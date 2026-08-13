import { createClient } from '@supabase/supabase-js';
import readline from 'readline/promises';
import { stdin as input, stdout as output } from 'process';
import fs from 'fs';
import path from 'path';
import dotenv from 'dotenv';

// Load .env if it exists in the script directory
const scriptDir = path.dirname(new URL(import.meta.url).pathname);
const envPath = path.join(scriptDir, '.env');
if (fs.existsSync(envPath)) {
  dotenv.config({ path: envPath });
}

// Color helpers
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m',
};

function logSuccess(msg) {
  console.log(`${colors.green}✔ ${msg}${colors.reset}`);
}

function logInfo(msg) {
  console.log(`${colors.cyan}ℹ ${msg}${colors.reset}`);
}

function logWarn(msg) {
  console.log(`${colors.yellow}⚠ ${msg}${colors.reset}`);
}

function logError(msg) {
  console.error(`${colors.red}✘ Error: ${msg}${colors.reset}`);
}

const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

async function main() {
  const rl = readline.createInterface({ input, output });

  console.log(`\n${colors.bright}${colors.red}=== Cuboid Flutter Template Tenant Permanent Deletion Tool ===${colors.reset}`);
  console.log(`${colors.yellow}This permanently deletes a tenant and ALL of its data (parties, vehicles,`);
  console.log(`drivers, agreements, work orders, invoices, settlements, payments, staff).`);
  console.log(`There is no undo.${colors.reset}\n`);

  try {
    // 1. Choose Environment
    console.log(`${colors.bright}Select Environment:${colors.reset}`);
    console.log('  1) Development (Local)');
    console.log('  2) Production (Hosted)');
    console.log('  3) Custom URL & Key');

    let envChoice = await rl.question('\nChoice (1-3) [default: 1]: ');
    envChoice = envChoice.trim() || '1';

    let supabaseUrl = '';
    let secretKey = '';
    let envName = '';

    if (envChoice === '1') {
      envName = 'Development';
      supabaseUrl = process.env.DEV_SUPABASE_URL || 'http://127.0.0.1:54321';
      secretKey = process.env.DEV_SUPABASE_SECRET_KEY;
    } else if (envChoice === '2') {
      envName = 'Production';
      supabaseUrl = process.env.PROD_SUPABASE_URL || 'https://uscoxxirwavojgfbngxe.supabase.co';
      secretKey = process.env.PROD_SUPABASE_SECRET_KEY;
    } else if (envChoice === '3') {
      envName = 'Custom';
      supabaseUrl = await rl.question('Enter Supabase API URL: ');
      secretKey = await rl.question('Enter Supabase Secret Key: ');
    } else {
      throw new Error('Invalid choice.');
    }

    supabaseUrl = supabaseUrl.trim();
    if (!supabaseUrl) {
      throw new Error('Supabase URL cannot be empty.');
    }

    if (!secretKey) {
      logWarn(`Secret Key not found in environment for ${envName}.`);
      secretKey = await rl.question('Please enter the SUPABASE_SECRET_KEY: ');
    }
    secretKey = secretKey.trim();

    if (!secretKey) {
      throw new Error('Supabase Secret Key cannot be empty.');
    }

    logInfo(`Connecting to ${envName} at ${supabaseUrl}...`);
    const supabase = createClient(supabaseUrl, secretKey, {
      auth: {
        persistSession: false,
        autoRefreshToken: false,
      },
    });

    // 2. Collect target details
    console.log(`\n${colors.bright}${colors.blue}--- Tenant To Delete ---${colors.reset}`);

    let tenantId = (await rl.question('Tenant UUID: ')).trim();
    if (!UUID_RE.test(tenantId)) throw new Error('Tenant UUID is not a valid UUID.');

    let userId = (await rl.question('Tenant User UUID (owner/staff being removed): ')).trim();
    if (!UUID_RE.test(userId)) throw new Error('Tenant User UUID is not a valid UUID.');

    let email = (await rl.question('User Email (for cross-check): ')).trim().toLowerCase();
    if (!email || !email.includes('@')) throw new Error('Valid email is required.');

    // 3. Look up and cross-verify before showing anything destructive
    logInfo('Looking up tenant...');
    const { data: tenant, error: tenantError } = await supabase
      .from('tenants')
      .select('id, name')
      .eq('id', tenantId)
      .maybeSingle();

    if (tenantError) throw new Error(`Failed to look up tenant: ${tenantError.message}`);
    if (!tenant) throw new Error(`No tenant found with ID ${tenantId}.`);

    logInfo('Looking up user...');
    const { data: userData, error: userError } = await supabase.auth.admin.getUserById(userId);
    if (userError || !userData?.user) {
      throw new Error(`No auth user found with ID ${userId}.`);
    }
    if (userData.user.email?.toLowerCase() !== email) {
      throw new Error(
        `Email mismatch: provided "${email}" does not match auth user's email "${userData.user.email}". Aborting to avoid targeting the wrong account.`
      );
    }

    const { data: member, error: memberError } = await supabase
      .from('tenant_members')
      .select('role, status')
      .eq('tenant_id', tenantId)
      .eq('user_id', userId)
      .maybeSingle();
    if (memberError) throw new Error(`Failed to verify tenant membership: ${memberError.message}`);
    if (!member) {
      logWarn(`User ${email} is not a member of tenant "${tenant.name}". Continuing will still delete the tenant, but only this user's auth account.`);
    }

    // 4. Show exactly what's about to happen and require typed confirmation
    console.log(`\n${colors.bright}${colors.red}--- ABOUT TO PERMANENTLY DELETE ---${colors.reset}`);
    console.log(`  Environment:   ${colors.bright}${envName}${colors.reset}`);
    console.log(`  Tenant Name:   ${tenant.name}`);
    console.log(`  Tenant ID:     ${tenant.id}`);
    console.log(`  User Email:    ${email}`);
    console.log(`  User ID:       ${userId}${member ? ` (role: ${member.role}, status: ${member.status})` : ''}`);
    console.log(`\n${colors.yellow}This deletes every party, vehicle, driver, agreement, route rate, work`);
    console.log(`order, expense, invoice, settlement, payment and staff membership under this`);
    console.log(`tenant, then the tenant itself and this user's auth account. Other staff`);
    console.log(`accounts (if any) are unlinked but not deleted. This cannot be undone.${colors.reset}\n`);

    const confirm = await rl.question(`Type the tenant name exactly ("${tenant.name}") to proceed: `);
    if (confirm.trim() !== tenant.name) {
      logInfo('Confirmation did not match. Deletion cancelled.');
      rl.close();
      return;
    }

    console.log(`\n${colors.cyan}Deleting tenant data...${colors.reset}`);

    const { error: deleteError } = await supabase.rpc('delete_tenant_permanently', {
      p_tenant_id: tenantId,
    });
    if (deleteError) {
      throw new Error(`Tenant data deletion failed (nothing was committed): ${deleteError.message}`);
    }
    logSuccess('Tenant data deleted.');

    logInfo('Deleting auth user...');
    const { error: authDeleteError } = await supabase.auth.admin.deleteUser(userId);
    if (authDeleteError) {
      logWarn(`Tenant data was deleted, but removing the auth user failed: ${authDeleteError.message}`);
    } else {
      logSuccess('Auth user deleted.');
    }

    console.log(`\n${colors.bright}${colors.green}=== TENANT PERMANENTLY DELETED ===${colors.reset}\n`);

  } catch (error) {
    logError(error.message);
  } finally {
    rl.close();
  }
}

main();
