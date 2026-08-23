import { IsString, IsOptional, IsUUID } from 'class-validator';

export class UpdateUserHierarchyDto {
  @IsString()
  @IsOptional()
  department?: string | null;

  @IsUUID()
  @IsOptional()
  managerId?: string | null;
}
