import { IsString, IsOptional } from 'class-validator';

export class ApprovalActionDto {
  @IsString()
  @IsOptional()
  comment?: string;
}
