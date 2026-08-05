import { createClient } from '@supabase/supabase-js';
import dotenv from 'dotenv';
import fs from 'fs';
import path from 'path';
import { stdin as input, stdout as output } from 'process';
import readline from 'readline/promises';

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

async function main() {
  const rl = readline.createInterface({ input, output });

  console.log(`\n${colors.bright}${colors.blue}=== Cuboid Flutter Template Tenant Onboarding Tool ===${colors.reset}\n`);

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

    // Ensure we have a URL and Secret Key
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

    // 2. Collect Onboarding Details
    console.log(`\n${colors.bright}${colors.blue}--- Tenant & Owner Details ---${colors.reset}`);

    // Default values mirror the test tenant seed
    const isDev = envName === 'Development';
    const defaultTenant = isDev ? 'Fleet Go Test' : '';
    const defaultEmail = isDev ? 'test@yopmail.com' : '';
    const defaultPassword = isDev ? 'Test@123' : '';
    const defaultName = isDev ? 'Fleet Go Test Owner' : '';

    const tenantNamePrompt = defaultTenant ? `Tenant Name [default: ${defaultTenant}]: ` : 'Tenant Name: ';
    let tenantName = await rl.question(tenantNamePrompt);
    tenantName = tenantName.trim() || defaultTenant;
    if (!tenantName) throw new Error('Tenant name is required.');

    const emailPrompt = defaultEmail ? `Owner Email [default: ${defaultEmail}]: ` : 'Owner Email: ';
    let email = await rl.question(emailPrompt);
    email = email.trim().toLowerCase() || defaultEmail;
    if (!email || !email.includes('@')) throw new Error('Valid owner email is required.');

    const passwordPrompt = defaultPassword ? `Owner Password [default: ${defaultPassword}]: ` : 'Owner Password: ';
    let password = await rl.question(passwordPrompt);
    password = password.trim() || defaultPassword;
    if (password.length < 6) throw new Error('Password must be at least 6 characters.');

    const namePrompt = defaultName ? `Owner Display Name [default: ${defaultName}]: ` : 'Owner Display Name: ';
    let displayName = await rl.question(namePrompt);
    displayName = displayName.trim() || defaultName;
    if (!displayName) throw new Error('Owner display name is required.');

    console.log(`\n${colors.yellow}Summary of onboarding data:${colors.reset}`);
    console.log(`  Environment:  ${colors.bright}${envName}${colors.reset}`);
    console.log(`  Tenant Name:  ${tenantName}`);
    console.log(`  Owner Email:  ${email}`);
    console.log(`  Display Name: ${displayName}`);
    console.log(`  Password:     [hidden]`);

    const confirm = await rl.question('\nProceed with onboarding? (y/n) [default: y]: ');
    if (confirm.trim().toLowerCase() === 'n') {
      logInfo('Onboarding cancelled.');
      rl.close();
      return;
    }

    console.log(`\n${colors.cyan}Starting onboarding process...${colors.reset}`);

    let userId = null;
    let tenantId = null;

    // Check if user already exists
    logInfo('Checking for existing user...');
    // We search via supabaseAdmin auth API. Note that listUsers is paginated but we can check if they exist
    const { data: usersData, error: usersError } = await supabase.auth.admin.listUsers();
    if (usersError) {
      throw new Error(`Failed to list users to check existence: ${usersError.message}`);
    }

    const existingUser = usersData.users.find(u => u.email.toLowerCase() === email);

    if (existingUser) {
      logWarn(`User with email ${email} already exists in auth.users.`);
      const reuseUser = await rl.question('Reuse this user? (y/n) [default: y]: ');
      if (reuseUser.trim().toLowerCase() === 'n') {
        throw new Error('Onboarding aborted because user already exists and reuse was declined.');
      }
      userId = existingUser.id;
      logSuccess(`Reusing existing user with ID: ${userId}`);
    } else {
      // Create user
      logInfo('Creating new user in auth...');
      const { data: userData, error: userError } = await supabase.auth.admin.createUser({
        email,
        password,
        email_confirm: true,
        user_metadata: { display_name: displayName }
      });

      if (userError || !userData.user) {
        throw new Error(`Failed to create user: ${userError?.message || 'Unknown error'}`);
      }
      userId = userData.user.id;
      logSuccess(`Created auth user with ID: ${userId}`);
    }

    // Check if tenant already exists
    logInfo('Checking for existing tenant...');
    const { data: existingTenant, error: tenantSearchError } = await supabase
      .from('tenants')
      .select('id')
      .eq('name', tenantName)
      .maybeSingle();

    if (tenantSearchError) {
      throw new Error(`Failed to query tenants: ${tenantSearchError.message}`);
    }

    if (existingTenant) {
      logWarn(`Tenant with name "${tenantName}" already exists.`);
      const reuseTenant = await rl.question('Link user to this existing tenant? (y/n) [default: y]: ');
      if (reuseTenant.trim().toLowerCase() === 'n') {
        throw new Error('Onboarding aborted because tenant already exists and reuse was declined.');
      }
      tenantId = existingTenant.id;
      logSuccess(`Reusing existing tenant with ID: ${tenantId}`);
    } else {
      // Create tenant
      logInfo('Creating new tenant...');
      const { data: newTenant, error: newTenantError } = await supabase
        .from('tenants')
        .insert({ name: tenantName })
        .select('id')
        .single();

      if (newTenantError || !newTenant) {
        throw new Error(`Failed to create tenant: ${newTenantError?.message || 'Unknown error'}`);
      }
      tenantId = newTenant.id;
      logSuccess(`Created tenant with ID: ${tenantId}`);
    }

    // Create User Profile
    logInfo('Updating user profile...');
    const { error: profileError } = await supabase
      .from('user_profiles')
      .upsert({ user_id: userId, display_name: displayName });

    if (profileError) {
      throw new Error(`Failed to create/update user profile: ${profileError.message}`);
    }
    logSuccess('User profile set up.');

    // Check if already a member of this tenant
    logInfo('Checking tenant membership...');
    const { data: existingMember, error: memberSearchError } = await supabase
      .from('tenant_members')
      .select('id')
      .eq('tenant_id', tenantId)
      .eq('user_id', userId)
      .maybeSingle();

    if (memberSearchError) {
      throw new Error(`Failed to query tenant membership: ${memberSearchError.message}`);
    }

    let memberId = null;

    if (existingMember) {
      memberId = existingMember.id;
      logSuccess(`User is already a member of this tenant (Member ID: ${memberId}).`);

      // Update role/status to be active owner just in case
      const { error: updateMemberError } = await supabase
        .from('tenant_members')
        .update({ role: 'owner', status: 'active', accepted_at: new Date().toISOString() })
        .eq('id', memberId);

      if (updateMemberError) {
        logWarn(`Could not force role to owner/active: ${updateMemberError.message}`);
      }
    } else {
      // Create tenant member
      logInfo('Creating tenant membership as owner...');
      const { data: newMember, error: newMemberError } = await supabase
        .from('tenant_members')
        .insert({
          tenant_id: tenantId,
          user_id: userId,
          display_name: displayName,
          email: email,
          role: 'owner',
          status: 'active',
          accepted_at: new Date().toISOString()
        })
        .select('id')
        .single();

      if (newMemberError || !newMember) {
        throw new Error(`Failed to create tenant membership: ${newMemberError?.message || 'Unknown error'}`);
      }
      memberId = newMember.id;
      logSuccess(`Tenant member created with ID: ${memberId}`);
    }

    // Grant access packs
    logInfo('Assigning access packs (operations, master_data, money, reports)...');
    const packs = ['operations', 'master_data', 'money', 'reports'].map(pack => ({
      member_id: memberId,
      pack
    }));

    const { error: packsError } = await supabase
      .from('member_access_packs')
      .upsert(packs);

    if (packsError) {
      throw new Error(`Failed to assign access packs: ${packsError.message}`);
    }
    logSuccess('Access packs assigned successfully.');

    console.log(`\n${colors.bright}${colors.green}=== ONBOARDING SUCCESSFUL ===${colors.reset}\n`);
    console.log(`Tenant Name:    ${colors.bright}${tenantName}${colors.reset}`);
    console.log(`Tenant ID:      ${tenantId}`);
    console.log(`Owner Email:    ${email}`);
    console.log(`Owner Member ID: ${memberId}`);
    console.log(`Owner User ID:   ${userId}\n`);
    logInfo('The owner can now log in to the application using the credentials provided.');

  } catch (error) {
    logError(error.message);
  } finally {
    rl.close();
  }
}

main();
