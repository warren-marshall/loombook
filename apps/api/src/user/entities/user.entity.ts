import {
  Entity,
  PrimaryGeneratedColumn,
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
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  firstName!: string;

  @Column()
  lastName!: string;

  @Column({ select: false })
  password!: string;

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
