import { IsString, IsNumber, IsBoolean, IsOptional, Min, Max } from 'class-validator';
import { Type } from 'class-transformer';

export class CreateOfficeBranchDto {
  @IsString()
  name: string;

  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude: number;

  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(10)
  radiusMeters?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

export class UpdateOfficeBranchDto {
  @IsOptional()
  @IsString()
  name?: string;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-90)
  @Max(90)
  latitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(-180)
  @Max(180)
  longitude?: number;

  @IsOptional()
  @Type(() => Number)
  @IsNumber()
  @Min(10)
  radiusMeters?: number;

  @IsOptional()
  @IsBoolean()
  isActive?: boolean;
}

