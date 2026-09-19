import {
  Entity,
  PrimaryGeneratedColumn,
  Column,
  CreateDateColumn,
  ManyToOne,
  JoinColumn,
} from 'typeorm';
import { Client } from '../../client/entities/client.entity';
import { Lead } from '../../lead/entities/lead.entity';
import { Contact } from '../../contact/entities/contact.entity';

@Entity('email_messages')
export class EmailMessage {
  @PrimaryGeneratedColumn('uuid')
  id!: string;

  @Column({ nullable: true })
  subject?: string;

  @Column({ type: 'text' })
  message!: string;

  @ManyToOne(() => Client, (client) => client.messages, {
    onDelete: 'CASCADE',
    nullable: true,
  })
  @JoinColumn({ name: 'clientId' })
  client?: Client;

  @Column({ type: 'uuid', nullable: true })
  clientId?: string;

  @ManyToOne(() => Lead, (lead) => lead.messages, {
    onDelete: 'CASCADE',
    nullable: true,
  })
  @JoinColumn({ name: 'leadId' })
  lead?: Lead;

  @Column({ type: 'uuid', nullable: true })
  leadId?: string;

  @ManyToOne(() => Contact, { onDelete: 'SET NULL', nullable: true })
  @JoinColumn({ name: 'contactId' })
  contact?: Contact;

  @Column({ type: 'uuid', nullable: true })
  contactId?: string;

  @CreateDateColumn({ type: 'timestamptz' })
  createdAt!: Date;
}
