import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateOfficeBranchDto,
  UpdateOfficeBranchDto,
} from './dto/office-branch.dto';

@Injectable()
export class CompanySettingsService {
  constructor(private readonly prisma: PrismaService) {}

  getBranches() {
    return this.prisma.officeBranch.findMany({ orderBy: { name: 'asc' } });
  }

  getActiveBranches() {
    return this.prisma.officeBranch.findMany({
      where: { isActive: true },
      orderBy: { name: 'asc' },
    });
  }

  async addBranch(data: CreateOfficeBranchDto) {
    return this.prisma.officeBranch.create({
      data: {
        name: data.name.trim(),
        latitude: data.latitude,
        longitude: data.longitude,
        radiusMeters: data.radiusMeters ?? 200,
        isActive: data.isActive ?? true,
      },
    });
  }

  async updateBranch(id: string, data: UpdateOfficeBranchDto) {
    try {
      return await this.prisma.officeBranch.update({
        where: { id },
        data,
      });
    } catch (error: unknown) {
      if (this.isRecordNotFound(error)) {
        throw new NotFoundException('Branch not found');
      }
      throw error;
    }
  }

  async deleteBranch(id: string) {
    try {
      await this.prisma.officeBranch.delete({ where: { id } });
      return { success: true };
    } catch (error: unknown) {
      if (this.isRecordNotFound(error)) {
        throw new NotFoundException('Branch not found');
      }
      throw error;
    }
  }

  private isRecordNotFound(error: unknown): boolean {
    return (
      typeof error === 'object' &&
      error !== null &&
      'code' in error &&
      (error as { code?: string }).code === 'P2025'
    );
  }
}
