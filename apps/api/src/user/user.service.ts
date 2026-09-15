import { Injectable, NotFoundException } from '@nestjs/common';
import { InjectRepository } from '@nestjs/typeorm';
import { Repository } from 'typeorm';
import * as bcrypt from 'bcrypt';
import { User } from './entities/user.entity';
import { CreateUserDto } from './dto/create-user.dto';
import { UpdateUserDto } from './dto/update-user.dto';

const SALT_ROUNDS = 10;

@Injectable()
export class UserService {
  constructor(
    @InjectRepository(User)
    private readonly userRepository: Repository<User>,
  ) {}

  async create(createUserDto: CreateUserDto): Promise<User> {
    const user = this.userRepository.create({
      firstName: createUserDto.firstname,
      lastName: createUserDto.lastname,
      email: createUserDto.email,
      password: await bcrypt.hash(createUserDto.password, SALT_ROUNDS),
      ...(createUserDto.role !== undefined && { userRole: createUserDto.role }),
    });

    return this.userRepository.save(user);
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
    return this.userRepository
      .createQueryBuilder('user')
      .addSelect('user.password')
      .where('user.email = :email', { email })
      .getOne();
  }

  verifyPassword(plain: string, hash: string): Promise<boolean> {
    return bcrypt.compare(plain, hash);
  }

  async update(id: string, updateUserDto: UpdateUserDto): Promise<User> {
    await this.findOne(id);

    await this.userRepository.update(id, {
      ...(updateUserDto.firstname !== undefined && {
        firstName: updateUserDto.firstname,
      }),
      ...(updateUserDto.lastname !== undefined && {
        lastName: updateUserDto.lastname,
      }),
      ...(updateUserDto.email !== undefined && { email: updateUserDto.email }),
      ...(updateUserDto.role !== undefined && { userRole: updateUserDto.role }),
      ...(updateUserDto.password !== undefined && {
        password: await bcrypt.hash(updateUserDto.password, SALT_ROUNDS),
      }),
    });

    return this.findOne(id);
  }

  async remove(id: string): Promise<void> {
    const user = await this.findOne(id);
    await this.userRepository.remove(user);
  }
}
