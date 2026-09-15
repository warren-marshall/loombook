import {
  IsString,
  IsNotEmpty,
  IsOptional,
  IsEnum,
  IsDateString,
  IsInt,
  Min,
  Max,
  IsUUID,
  IsBoolean,
  IsArray,
  MaxLength,
} from 'class-validator';
import { TaskStatus } from '../entities/task.entity';

export class CreateTaskDto {
  @IsString()
  @IsNotEmpty()
  @MaxLength(200)
  name!: string;

  @IsOptional()
  @IsString()
  @MaxLength(2000)
  description?: string;

  @IsOptional()
  @IsEnum(TaskStatus)
  status?: TaskStatus;

  @IsNotEmpty()
  @IsUUID()
  projectId!: string;

  @IsOptional()
  @IsDateString()
  startDate?: string;

  @IsOptional()
  @IsDateString()
  dueDate?: string;

  @IsOptional()
  @IsInt()
  @Min(0)
  expectedDuration?: number;

  @IsOptional()
  @IsBoolean()
  isRecurring?: boolean;

  @IsOptional()
  @IsString()
  recurrencePattern?: string; // 'daily' | 'weekly' | 'monthly' | 'yearly'

  @IsOptional()
  @IsInt()
  @Min(1)
  recurrenceInterval?: number;

  @IsOptional()
  @IsInt()
  @Min(0)
  @Max(6)
  recurrenceDayOfWeek?: number;

  @IsOptional()
  @IsDateString()
  recurrenceEndDate?: string;

  @IsOptional()
  @IsInt()
  @Min(1)
  recurrenceCount?: number;

  @IsOptional()
  @IsUUID()
  recurringGroupId?: string;

  @IsOptional()
  @IsArray()
  @IsUUID('4', { each: true })
  dependsOnIds?: string[];

  @IsOptional()
  @IsString()
  @MaxLength(200)
  assigneeName?: string;

  @IsOptional()
  @IsUUID()
  assigneeUserId?: string;

  @IsOptional()
  @IsUUID()
  assigneeContactId?: string;
}
