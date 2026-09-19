import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  UpdateDateColumn,
  ManyToOne,
  JoinColumn,
  OneToMany,
} from 'typeorm';
import { User } from '../../user/entities/user.entity';
import { Contact } from '../../contact/entities/contact.entity';
import { EmailMessage } from '../../email-messages/entities/email-message.entity';
import { Project } from '../../project/entities/project.entity';

export enum LeadStatus {
  NEW = 'new',
  CONTACTED = 'contacted',
  CONTRACT_SENT = 'contract_sent',
  BOOKED = 'booked',
  LOST = 'lost',
  ARCHIVED = 'archived',
}

@Entity()
export class Lead {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  businessName!: string;

  @Column({ nullable: true })
  website?: string;

  @Column({
    type: 'enum',
    enum: LeadStatus,
    default: LeadStatus.NEW,
  })
  status!: LeadStatus;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'updatedByUserId' })
  updatedByUser?: User;

  @Column({ nullable: true })
  updatedByUserId?: string;

  @OneToMany(() => Contact, (contact) => contact.lead)
  contacts?: Contact[];

  @OneToMany(() => Project, (project) => project.lead)
  projects?: Project[];

  @OneToMany(() => EmailMessage, (message) => message.lead)
  messages?: EmailMessage[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt!: Date;

  @Column({ nullable: true })
  convertedToClientId?: string;
}
