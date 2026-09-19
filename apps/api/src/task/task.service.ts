import {
  Injectable,
  NotFoundException,
  BadRequestException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository, In } from 'typeorm';
import { Task, TaskStatus } from './entities/task.entity';
import { Project } from '../project/entities/project.entity';
import { User } from '../user/entities/user.entity';
import { Contact } from '../contact/entities/contact.entity';
import { CreateTaskDto } from './dto/create-task.dto';
import { UpdateTaskDto } from './dto/update-task.dto';

@Injectable()
export class TaskService {
  constructor(
    @InjectRepository(Task)
    private readonly taskRepository: Repository<Task>,
    @InjectRepository(Project)
    private readonly projectRepository: Repository<Project>,
  ) {}

  private async resolveProject(projectId: string): Promise<Project> {
    const project = await this.projectRepository.findOne({
      where: { id: projectId },
    });
    if (!project) {
      throw new NotFoundException(`Project with id ${projectId} not found`);
    }
    return project;
  }

  private async resolveDependencies(
    dependsOnIds: string[],
    ownTaskId?: string,
  ): Promise<Task[]> {
    if (!dependsOnIds || dependsOnIds.length === 0) {
      return [];
    }

    const uniqueIds = Array.from(new Set(dependsOnIds));

    if (ownTaskId && uniqueIds.includes(ownTaskId)) {
      throw new BadRequestException('A task cannot depend on itself');
    }

    const tasks = await this.taskRepository.find({
      where: { id: In(uniqueIds) },
    });

    if (tasks.length !== uniqueIds.length) {
      const foundIds = new Set(tasks.map((t) => t.id));
      const missing = uniqueIds.filter((id) => !foundIds.has(id));
      throw new NotFoundException(`Task(s) not found: ${missing.join(', ')}`);
    }

    return tasks;
  }

  private diffInDays(previous: Date | null, next: Date | null): number {
    if (!previous || !next) return 0;
    const prevTime = new Date(previous).setHours(0, 0, 0, 0);
    const nextTime = new Date(next).setHours(0, 0, 0, 0);
    return Math.round((nextTime - prevTime) / (1000 * 60 * 60 * 24));
  }

  private addDays(date: Date, days: number): Date {
    const result = new Date(date);
    result.setDate(result.getDate() + days);
    return result;
  }

  private async shiftDependentsRecursive(
    taskId: string,
    deltaDays: number,
    visited: Set<string> = new Set(),
  ): Promise<void> {
    if (deltaDays === 0 || visited.has(taskId)) return;
    visited.add(taskId);

    const task = await this.taskRepository.findOne({
      where: { id: taskId },
      relations: { dependentTasks: true },
    });
    if (!task?.dependentTasks?.length) return;

    for (const dependent of task.dependentTasks) {
      if (visited.has(dependent.id)) continue;

      if (dependent.startDate) {
        dependent.startDate = this.addDays(dependent.startDate, deltaDays);
      }
      if (dependent.dueDate) {
        dependent.dueDate = this.addDays(dependent.dueDate, deltaDays);
      }

      // Safe entity persistence using save() rather than query builder update()
      await this.taskRepository.save(dependent);

      await this.shiftDependentsRecursive(dependent.id, deltaDays, visited);
    }
  }

  async create(
    createTaskDto: CreateTaskDto,
    createdById: string,
  ): Promise<Task> {
    const {
      projectId,
      dependsOnIds,
      assigneeUserId,
      assigneeContactId,
      ...rest
    } = createTaskDto;

    const project = await this.resolveProject(projectId);
    const dependsOn = await this.resolveDependencies(dependsOnIds ?? []);

    const task = this.taskRepository.create({
      ...rest,
      project,
      dependsOn,
      assigneeUser: assigneeUserId ? { id: assigneeUserId } : null,
      assigneeContact: assigneeContactId ? { id: assigneeContactId } : null,
      createdBy: { id: createdById } as User,
      completedAt: rest.status === TaskStatus.COMPLETED ? new Date() : null,
    });

    const savedTask = await this.taskRepository.save(task);
    return this.findOne(savedTask.id);
  }

  findAll(): Promise<Task[]> {
    return this.taskRepository.find({
      relations: {
        project: {
          client: true,
        },
        createdBy: true,
        lastModifiedBy: true,
        dependsOn: true,
        assigneeUser: true,
        assigneeContact: true,
      },
      order: { createdAt: 'DESC' },
    });
  }

  async findOne(id: string): Promise<Task> {
    const task = await this.taskRepository.findOne({
      where: { id },
      relations: {
        project: {
          client: true,
        },
        createdBy: true,
        lastModifiedBy: true,
        dependsOn: true,
        assigneeUser: true,
        assigneeContact: true,
      },
    });
    if (!task) {
      throw new NotFoundException(`Task with id ${id} not found`);
    }
    return task;
  }

  async update(
    id: string,
    updateTaskDto: UpdateTaskDto,
    lastModifiedById: string,
  ): Promise<Task> {
    // 1. Explicitly pull out non-entity fields from the DTO
    const {
      projectId,
      dependsOnIds,
      status,
      cascadeDependencies,
      assigneeUserId,
      assigneeContactId,
      ...rest
    } = updateTaskDto;

    const task = await this.findOne(id);
    const previousDueDate = task.dueDate;

    // 2. Safely assign standard entity fields
    Object.assign(task, rest);

    if (projectId !== undefined) {
      task.project = await this.resolveProject(projectId);
    }

    if (assigneeUserId !== undefined) {
      task.assigneeUser = assigneeUserId
        ? ({ id: assigneeUserId } as User)
        : null;
    }

    if (assigneeContactId !== undefined) {
      task.assigneeContact = assigneeContactId
        ? ({ id: assigneeContactId } as Contact)
        : null;
    }

    if (status !== undefined && status !== task.status) {
      if (status === TaskStatus.COMPLETED) {
        task.completedAt = new Date();
      } else if (task.status === TaskStatus.COMPLETED) {
        task.completedAt = null;
      }
      task.status = status;
    }

    if (dependsOnIds !== undefined) {
      task.dependsOn = await this.resolveDependencies(dependsOnIds, id);
    }

    if (lastModifiedById) {
      task.lastModifiedBy = { id: lastModifiedById } as User;
    }

    // 3. Persist entity
    await this.taskRepository.save(task);

    // 4. Handle cascade logic using the extracted boolean
    if (cascadeDependencies) {
      const deltaDays = this.diffInDays(previousDueDate, task.dueDate);
      if (deltaDays !== 0) {
        await this.shiftDependentsRecursive(id, deltaDays);
      }
    }

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const task = await this.findOne(id);
    await this.taskRepository.remove(task);
  }
}
