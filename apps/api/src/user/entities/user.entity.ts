import {
  Entity,
  PrimaryColumn,
  Column,
  CreateDateColumn,
} from 'typeorm';

export enum UserRole {
  ADMIN = 'admin',
  BASIC = 'basic',
}

export enum UserType {
  PHOTOGRAPHER = 'photographer',
}

@Entity('user')
export class User {
  // Same id as the account in Supabase Auth (auth.users). Rows are created and
  // kept in sync by database triggers (supabase/migrations), not by the API.
  @PrimaryColumn('uuid')
  id!: string;

  @Column()
  firstName!: string;

  @Column()
  lastName!: string;

  @Column({ unique: true })
  email!: string;

  @Column({
    type: 'enum',
    enum: UserRole,
    default: UserRole.ADMIN,
  })
  userRole!: UserRole;

  @Column({
    type: 'enum',
    enum: UserType,
    default: UserType.PHOTOGRAPHER,
  })
  userType!: UserType;

  @CreateDateColumn()
  createdAt!: Date;
}
