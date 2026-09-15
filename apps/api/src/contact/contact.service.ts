import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Contact } from './entities/contact.entity';
import { Client } from '../client/entities/client.entity';
import { Lead } from '../lead/entities/lead.entity';
import { CreateContactDto } from './dto/create-contact.dto';
import { UpdateContactDto } from './dto/update-contact.dto';

@Injectable()
export class ContactService {
  constructor(
    @InjectRepository(Contact)
    private readonly contactRepository: Repository<Contact>,
    @InjectRepository(Client)
    private readonly clientRepository: Repository<Client>,
    @InjectRepository(Lead)
    private readonly leadRepository: Repository<Lead>,
  ) {}

  async create(createContactDto: CreateContactDto): Promise<Contact> {
    if (createContactDto.clientId) {
      const client = await this.clientRepository.findOneBy({
        id: createContactDto.clientId,
      });
      if (!client) {
        throw new NotFoundException(
          `Client with id ${createContactDto.clientId} not found`,
        );
      }
    }

    if (createContactDto.leadId) {
      const lead = await this.leadRepository.findOneBy({
        id: createContactDto.leadId,
      });
      if (!lead) {
        throw new NotFoundException(
          `Lead with id ${createContactDto.leadId} not found`,
        );
      }
    }

    const contact = this.contactRepository.create(createContactDto);
    return this.contactRepository.save(contact);
  }

  findAll(): Promise<Contact[]> {
    return this.contactRepository.find();
  }

  async findOne(id: string): Promise<Contact> {
    const contact = await this.contactRepository.findOneBy({ id });
    if (!contact) {
      throw new NotFoundException(`Contact with id ${id} not found`);
    }
    return contact;
  }

  async update(
    id: string,
    updateContactDto: UpdateContactDto,
  ): Promise<Contact> {
    const contact = await this.findOne(id);
    Object.assign(contact, updateContactDto);
    return this.contactRepository.save(contact);
  }

  async remove(id: string): Promise<void> {
    const contact = await this.findOne(id);
    await this.contactRepository.remove(contact);
  }
}
