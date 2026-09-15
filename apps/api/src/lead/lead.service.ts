import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository, InjectDataSource } from '@nestjs/typeorm';
import { Repository, DataSource, Not } from 'typeorm';
import { Lead, LeadStatus } from './entities/lead.entity';
import { Client, ClientStatus } from '../client/entities/client.entity';
import { Contact } from '../contact/entities/contact.entity';
import { EmailMessage } from '../email-messages/entities/email-message.entity';
import { Contract } from 'src/contract/entities/contract.entity';
import { Attachment } from 'src/attachment/entities/attachment.entity';
import { CreateLeadDto } from './dto/create-lead.dto';
import { UpdateLeadDto } from './dto/update-lead.dto';
import { GmailService } from '../gmail/gmail.service';

@Injectable()
export class LeadsService {
  constructor(
    @InjectRepository(Lead)
    private readonly leadRepository: Repository<Lead>,
    private readonly gmailService: GmailService,
    @InjectDataSource()
    private readonly dataSource: DataSource,
  ) {}

  async create(createLeadDto: CreateLeadDto): Promise<Lead> {
    const newLeadId = await this.dataSource.transaction(async (manager) => {
      const lead = manager.create(Lead, {
        businessName: createLeadDto.businessName,
        website: createLeadDto.website,
      });
      const savedLead = await manager.save(lead);

      const contact = manager.create(Contact, {
        name: createLeadDto.name,
        email: createLeadDto.email,
        isPrimary: true,
        leadId: savedLead.id,
      });
      const savedContact = await manager.save(contact);

      const message = manager.create(EmailMessage, {
        subject: createLeadDto.subject,
        message: createLeadDto.message,
        leadId: savedLead.id,
        contactId: savedContact.id,
      });
      await manager.save(message);

      return savedLead.id;
    });

    this.gmailService
      .sendLeadNotification({
        name: createLeadDto.name,
        email: createLeadDto.email,
        subject: createLeadDto.subject,
        businessName: createLeadDto.businessName,
        website: createLeadDto.website,
        message: createLeadDto.message,
      })
      .catch(() => {
        // Already logged inside GmailService
      });

    return this.findOne(newLeadId);
  }

  findAll(): Promise<Lead[]> {
    return this.leadRepository.find({
      where: { status: Not(LeadStatus.BOOKED) },
      relations: { updatedByUser: true, contacts: true, messages: true },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Lead> {
    const lead = await this.leadRepository.findOne({
      where: { id },
      relations: { updatedByUser: true, contacts: true, messages: true },
    });
    if (!lead) {
      throw new NotFoundException(`Lead with id ${id} not found`);
    }
    return lead;
  }

  async update(
    id: string,
    updateLeadDto: UpdateLeadDto,
    updatedByUserId: string,
  ): Promise<Lead> {
    const lead = await this.findOne(id);
    const wasAlreadyBooked = lead.status === LeadStatus.BOOKED;

    await this.leadRepository.update(id, {
      ...(updateLeadDto.businessName !== undefined && {
        businessName: updateLeadDto.businessName,
      }),
      ...(updateLeadDto.website !== undefined && {
        website: updateLeadDto.website,
      }),
      ...(updateLeadDto.status !== undefined && {
        status: updateLeadDto.status,
      }),
      updatedByUserId,
    });

    const updatedLead = await this.findOne(id);
    const justBecameBooked =
      updatedLead.status === LeadStatus.BOOKED && !wasAlreadyBooked;

    if (justBecameBooked) {
      await this.convertLeadToClient(updatedLead);
    }

    return this.findOne(id);
  }

  private async convertLeadToClient(lead: Lead): Promise<void> {
    await this.dataSource.transaction(async (manager) => {
      const client = manager.create(Client, {
        companyName: lead.businessName,
        website: lead.website,
        status: ClientStatus.ACTIVE,
        convertedFromLeadId: lead.id,
      });
      const savedClient = await manager.save(client);

      for (const contact of lead.contacts ?? []) {
        await manager.update(Contact, contact.id, {
          clientId: savedClient.id,
        });
      }

      for (const message of lead.messages ?? []) {
        await manager.update(EmailMessage, message.id, {
          clientId: savedClient.id,
        });
      }

      await manager.update(
        Contract,
        { leadId: lead.id },
        { clientId: savedClient.id },
      );

      await manager.update(
        Attachment,
        { leadId: lead.id },
        { clientId: savedClient.id },
      );

      await manager.update(Lead, lead.id, {
        convertedToClientId: savedClient.id,
      });
    });
  }

  async remove(id: string): Promise<void> {
    const lead = await this.findOne(id);
    await this.leadRepository.remove(lead);
  }
}
