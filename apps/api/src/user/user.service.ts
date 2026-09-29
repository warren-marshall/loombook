import {
  BadRequestException,
  Injectable,
  NotFoundException,
} from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import { User, UserRole } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';
import { SupabaseService } from '../supabase/supabase.service';

/**
 * Accounts live in Supabase Auth; the `user` table is the app profile, kept in
 * sync by database triggers. Writes go through the auth admin API and reads
 * come from the profile table.
 */
@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
    private readonly supabase: SupabaseService,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const { data, error } = await this.supabase.admin.auth.admin.createUser({
      email: createUserDto.email,
      password: createUserDto.password,
      email_confirm: true,
      user_metadata: {
        firstName: createUserDto.firstname,
        lastName: createUserDto.lastname,
      },
      app_metadata: { role: createUserDto.role ?? UserRole.ADMIN },
    });
    if (error || !data.user) {
      throw new BadRequestException(error?.message ?? 'Could not create user');
    }

    return this.findOne(data.user.id);
  }

  findAll(): Promise<User[]> {
    return this.userRepository.find();
  }

  async findOne(id: string): Promise<User> {
    const user = await this.userRepository.findOneBy({ id });
    if (!user) {
      throw new NotFoundException(`User with id ${id} not found`);
    }
    return user;
  }

  findByEmail(email: string): Promise<User | null> {
    return this.userRepository.findOneBy({ email });
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    const current = await this.findOne(id);

    const { error } = await this.supabase.admin.auth.admin.updateUserById(id, {
      ...(updateUserDto.email !== undefined && { email: updateUserDto.email }),
      ...(updateUserDto.password !== undefined && {
        password: updateUserDto.password,
      }),
      user_metadata: {
        firstName: updateUserDto.firstname ?? current.firstName,
        lastName: updateUserDto.lastname ?? current.lastName,
      },
      ...(updateUserDto.role !== undefined && {
        app_metadata: { role: updateUserDto.role },
      }),
    });
    if (error) {
      throw new BadRequestException(error.message);
    }

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    await this.findOne(id);

    const { error } = await this.supabase.admin.auth.admin.deleteUser(id);
    if (error) {
      throw new BadRequestException(error.message);
    }
  }
}
