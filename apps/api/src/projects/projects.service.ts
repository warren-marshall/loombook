import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { Project } from './entities/project.entity';
import { Client } from '../client/entities/client.entity';
import { Lead } from '../lead/entities/lead.entity';
import { CreateProjectDto } from './dto/create-project.dto';
import { UpdateProjectDto } from './dto/update-project.dto';

@Injectable()
export class ProjectsService {
  constructor(
    @InjectRepository(Project)
    private readonly projectRepository: Repository<Project>,
    @InjectRepository(Client)
    private readonly clientRepository: Repository<Client>,
    @InjectRepository(Lead)
    private readonly leadRepository: Repository<Lead>,
  ) {}

  private async resolveClient(clientId: string): Promise<Client> {
    const client = await this.clientRepository.findOne({
      where: { id: clientId },
    });
    if (!client) {
      throw new NotFoundException(`Client with id ${clientId} not found`);
    }
    return client;
  }

  private async resolveLead(leadId: string): Promise<Lead> {
    const lead = await this.leadRepository.findOne({ where: { id: leadId } });
    if (!lead) {
      throw new NotFoundException(`Lead with id ${leadId} not found`);
    }
    return lead;
  }

  async create(
    createProjectDto: CreateProjectDto,
    createdById: string,
  ): Promise<Project> {
    const { clientId, leadId, ...rest } = createProjectDto;

    const client = clientId ? await this.resolveClient(clientId) : null;
    const lead = leadId ? await this.resolveLead(leadId) : null;

    const project = this.projectRepository.create({
      ...rest,
      client,
      lead,
      createdBy: { id: createdById },
    });

    return this.projectRepository.save(project);
  }

  findAll(): Promise<Project[]> {
    return this.projectRepository.find({
      relations: {
        client: true,
        lead: true,
        createdBy: true,
        lastModifiedBy: true,
        tasks: true,
      },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Project> {
    const project = await this.projectRepository.findOne({
      where: { id },
      relations: {
        client: true,
        lead: true,
        createdBy: true,
        lastModifiedBy: true,
        tasks: true,
      },
    });
    if (!project) {
      throw new NotFoundException(`Project with id ${id} not found`);
    }
    return project;
  }

  async update(
    id: string,
    updateProjectDto: UpdateProjectDto,
    lastModifiedById: string,
  ): Promise<Project> {
    const { clientId, leadId, ...rest } = updateProjectDto;

    const client = clientId ? await this.resolveClient(clientId) : undefined;
    const lead = leadId ? await this.resolveLead(leadId) : undefined;

    await this.projectRepository.update(id, {
      ...rest,
      ...(client !== undefined ? { client } : {}),
      ...(lead !== undefined ? { lead } : {}),
      lastModifiedBy: { id: lastModifiedById },
    });

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const project = await this.findOne(id);
    await this.projectRepository.remove(project);
  }
}
