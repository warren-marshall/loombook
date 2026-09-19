import { Module } from '@nestjs/common';
import { TypeOrmModule } from '@nestjs/typeorm';
import { ProjectService } from './project.service';
import { ProjectsController } from './project.controller';
import { Project } from './entities/project.entity';
import { Client } from '../client/entities/client.entity';
import { Lead } from '../lead/entities/lead.entity';
import { User } from '../user/entities/user.entity';

@Module({
  imports: [TypeOrmModule.forFeature([Project, Client, Lead, User])],
  controllers: [ProjectsController],
  providers: [ProjectService],
  exports: [ProjectService],
})
export class ProjectModule {}
