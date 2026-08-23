import { Injectable, NotFoundException, BadRequestException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import {
  CreateOfficeBranchDto,
  UpdateOfficeBranchDto,
} from './dto/office-branch.dto';
import { AssignUserBranchDto } from './dto/assign-user-branch.dto';
import { UpdateUserHierarchyDto } from './dto/update-user-hierarchy.dto';

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

  getUsersForBranchAssignment() {
    return this.prisma.user.findMany({
      where: { isActive: true },
      select: {
        id: true,
        employeeCode: true,
        name: true,
        department: true,
        role: true,
        branchId: true,
        branch: { select: { id: true, name: true, isActive: true } },
        managerId: true,
        manager: { select: { id: true, name: true, role: true } },
      },
      orderBy: [{ department: 'asc' }, { name: 'asc' }],
    });
  }

  async updateUserHierarchy(userId: string, data: UpdateUserHierarchyDto) {
    const employee = await this.prisma.user.findUnique({ where: { id: userId } });
    if (!employee) throw new NotFoundException('Employee not found');

    if (data.managerId && data.managerId === userId) {
      throw new BadRequestException('Self-assignment is not allowed');
    }

    return this.prisma.user.update({
      where: { id: userId },
      data: {
        department: data.department !== undefined ? data.department : undefined,
        managerId: data.managerId !== undefined ? data.managerId : undefined,
      },
      select: {
        id: true,
        employeeCode: true,
        name: true,
        department: true,
        role: true,
        branchId: true,
        branch: { select: { id: true, name: true, isActive: true } },
        managerId: true,
        manager: { select: { id: true, name: true, role: true } },
      },
    });
  }

  async assignUserBranch(userId: string, data: AssignUserBranchDto) {
    const [employee, branch] = await Promise.all([
      this.prisma.user.findUnique({ where: { id: userId } }),
      this.prisma.officeBranch.findUnique({ where: { id: data.branchId } }),
    ]);
    if (!employee) throw new NotFoundException('Employee not found');
    if (!branch) throw new NotFoundException('Office branch not found');
    if (!branch.isActive) {
      throw new NotFoundException('Office branch is inactive');
    }
    return this.prisma.user.update({
      where: { id: userId },
      data: { branchId: data.branchId },
      include: { branch: true },
    });
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
