import {
  IsNotEmpty,
  IsString,
  IsEnum,
  IsOptional,
  IsEmail,
  MinLength,
  Matches,
} from 'class-validator';
import { Transform } from 'class-transformer';
import { Role } from '../../auth/roles.enum';

export class CreateEmployeeDto {
  @IsNotEmpty({ message: 'Employee code is required' })
  @IsString()
  @Matches(/^[A-Z0-9_-]+$/i, {
    message:
      'Employee code must contain only alphanumeric characters, dashes, or underscores',
  })
  @Transform(({ value }: { value: unknown }): unknown =>
    typeof value === 'string' ? value.trim().toUpperCase() : value,
  )
  employeeCode!: string;

  @IsNotEmpty({ message: 'Full name is required' })
  @IsString()
  name!: string;

  @IsNotEmpty({ message: 'Password is required' })
  @IsString()
  @MinLength(8, { message: 'Password must be at least 8 characters long' })
  password!: string;

  @IsNotEmpty({ message: 'Role is required' })
  @IsEnum(Role, { message: 'Role must be a valid system role' })
  role!: Role;

  @IsOptional()
  @IsEmail({}, { message: 'Invalid email address format' })
  email?: string;

  @IsOptional()
  @IsString()
  department?: string;

  @IsOptional()
  @IsString()
  title?: string;

  @IsOptional()
  @IsString()
  managerId?: string;
}
