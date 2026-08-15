import { supabaseAdmin } from '../../src/config/supabase.config';
import { envConfig } from '../../src/config/env.config';
import { logger } from '../../src/utils/logger';

async function seedInitialAdmin() {
  logger.info('🌱 Starting initial database seed for Zobra Production ERP...');

  const adminEmail = envConfig.initialAdmin.email;
  const adminPassword = envConfig.initialAdmin.password;
  const adminName = envConfig.initialAdmin.name;

  try {
    // 1. Check if admin already exists in public.users
    const { data: existingUser } = await supabaseAdmin
      .from('users')
      .select('*')
      .eq('email', adminEmail)
      .maybeSingle();

    if (existingUser) {
      logger.info(`✅ System Admin account (${adminEmail}) already exists. Skipping auth creation.`);
      return;
    }

    let userId: string;

    // 2. Create or fetch Auth User in Supabase Auth (auth.users)
    const { data: authData, error: authErr } = await supabaseAdmin.auth.admin.createUser({
      email: adminEmail,
      password: adminPassword,
      email_confirm: true,
      user_metadata: { name: adminName, role: 'ADMIN' },
    });

    if (authErr || !authData.user) {
      const { data: listData } = await supabaseAdmin.auth.admin.listUsers();
      const match = listData.users.find(u => u.email === adminEmail);
      if (match) {
        userId = match.id;
        logger.info(`Found existing auth user ID: ${userId}`);
      } else {
        throw new Error(`Failed to create admin auth user: ${authErr?.message}`);
      }
    } else {
      userId = authData.user.id;
    }

    // 3. Create Profile in public.users
    const { error: profileErr } = await supabaseAdmin.from('users').upsert({
      id: userId,
      name: adminName,
      email: adminEmail,
      employee_id: 'EMP-001',
      role: 'ADMIN',
      status: 'APPROVED',
      admin_approved: true,
    });

    if (profileErr) {
      throw new Error(`Failed to create admin profile: ${profileErr.message}`);
    }

    logger.info(`🎉 System Admin created successfully! Email: ${adminEmail}`);
  } catch (error) {
    logger.error('❌ Seed execution failed:', error);
    process.exit(1);
  }
}

seedInitialAdmin();
