import { NestFactory } from '@nestjs/core';
import { AppModule } from './app.module';
import { UserService } from './user/user.service';
import { UserRole } from './user/entities/user.entity';

/**
 * Creates the first admin user through the real UserService (Nest app
 * context, no HTTP), bypassing the API — every endpoint requires a valid
 * JWT, so there's no other way to get the first account.
 * Usage: npm run seed:owner -- <email> <password> <firstname> <lastname>
 */
async function seed() {
  const app = await NestFactory.createApplicationContext(AppModule);
  const userService = app.get(UserService);

  const email = process.argv[2];
  const password = process.argv[3];
  const firstname = process.argv[4];
  const lastname = process.argv[5];

  if (!email || !password || !firstname || !lastname) {
    console.error(
      'Usage: npm run seed:owner -- <email> <password> <firstname> <lastname>',
    );
    await app.close();
    process.exit(1);
  }

  const existing = await userService.findByEmail(email);
  if (existing) {
    console.error(`A user with email ${email} already exists.`);
    await app.close();
    process.exit(1);
  }

  const user = await userService.create({
    email,
    password,
    firstname,
    lastname,
    role: UserRole.ADMIN,
  });

  console.log(`Created owner user: ${user.email} (id: ${user.id})`);
  await app.close();
}

void seed();
