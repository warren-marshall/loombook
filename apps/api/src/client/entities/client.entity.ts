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
import { Contact } from '../../contact/entities/contact.entity';
import { User } from '../../user/entities/user.entity';
import { EmailMessage } from '../../email-messages/entities/email-message.entity';
import { Project } from '../../projects/entities/project.entity';
import { Invoice } from 'src/invoice/entities/invoice.entity';

export enum ClientStatus {
  ACTIVE = 'active',
  PAST = 'past',
  CHURNED = 'churned',
}

@Entity('clients')
export class Client {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column()
  companyName!: string;

  @Column({ nullable: true })
  industry?: string;

  @Column({ nullable: true })
  website?: string;

  @Column({
    type: 'enum',
    enum: ClientStatus,
    default: ClientStatus.ACTIVE,
  })
  status!: ClientStatus;

  @Column({ nullable: true })
  convertedFromLeadId?: string;

  // Set once a Stripe Customer object exists for this client — typically at
  // contract signing, first invoice, or retainer setup. One Customer per
  // Client, reused across every Engagement they have with us.
  @Column({ nullable: true, unique: true })
  stripeCustomerId?: string;

  @Column({ type: 'uuid', nullable: true })
  updatedByUserId?: string;

  @ManyToOne(() => User, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'updatedByUserId' })
  updatedByUser?: User;

  @OneToMany(() => Project, (project) => project.client)
  projects?: Project[];

  @OneToMany(() => Contact, (contact) => contact.client)
  contacts?: Contact[];

  @OneToMany(() => EmailMessage, (message) => message.client)
  messages?: EmailMessage[];

  @OneToMany(() => Invoice, (invoice) => invoice.client)
  invoices?: Invoice[];

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;

  @UpdateDateColumn({ type: 'timestamptz' })
  updatedAt!: Date;
}
