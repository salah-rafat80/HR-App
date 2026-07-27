import { Injectable, NotFoundException } from '@nestjs/common';
import { PrismaService } from '../prisma/prisma.service';
import { CreateOfficeBranchDto, UpdateOfficeBranchDto } from './dto/office-branch.dto';

@Injectable()
export class CompanySettingsService {
  private inMemoryBranches = [
    {
      id: 'branch_main',
      name: 'Main Office',
      latitude: 30.286884,
      longitude: 31.756905,
      radiusMeters: 200,
      isActive: true,
      createdAt: new Date(),
      updatedAt: new Date(),
    },
  ];

  constructor(private prisma: PrismaService) {}

  async getBranches() {
    try {
      return await this.prisma.officeBranch.findMany({
        orderBy: { name: 'asc' },
      });
    } catch (e) {
      console.warn('Database offline, returning in-memory branches');
      return this.inMemoryBranches;
    }
  }

  async getActiveBranches() {
    try {
      return await this.prisma.officeBranch.findMany({
        where: { isActive: true },
        orderBy: { name: 'asc' },
      });
    } catch (e) {
      return this.inMemoryBranches.filter((b) => b.isActive);
    }
  }

  async addBranch(data: CreateOfficeBranchDto) {
    const payload = { ...data };
    delete (payload as any).id;
    try {
      return await this.prisma.officeBranch.create({
        data: {
          name: payload.name,
          latitude: payload.latitude,
          longitude: payload.longitude,
          radiusMeters: payload.radiusMeters ?? 200,
          isActive: payload.isActive ?? true,
        },
      });
    } catch (e) {
      console.warn('Database offline, adding branch in-memory');
      const newBranch = {
        id: `branch_${Date.now()}`,
        name: payload.name,
        latitude: payload.latitude,
        longitude: payload.longitude,
        radiusMeters: payload.radiusMeters ?? 200,
        isActive: payload.isActive ?? true,
        createdAt: new Date(),
        updatedAt: new Date(),
      };
      this.inMemoryBranches.push(newBranch);
      return newBranch;
    }
  }

  async updateBranch(id: string, data: UpdateOfficeBranchDto) {
    const payload = { ...data };
    delete (payload as any).id;

    try {
      const branch = await this.prisma.officeBranch.findUnique({ where: { id } });
      if (branch) {
        return await this.prisma.officeBranch.update({
          where: { id },
          data: payload,
        });
      }
    } catch (e) {
      console.warn('Database offline, updating branch in-memory');
    }

    const idx = this.inMemoryBranches.findIndex((b) => b.id === id);
    if (idx !== -1) {
      this.inMemoryBranches[idx] = {
        ...this.inMemoryBranches[idx],
        ...payload,
        updatedAt: new Date(),
      };
      return this.inMemoryBranches[idx];
    }
    throw new NotFoundException('Branch not found');
  }

  async deleteBranch(id: string) {
    try {
      const branch = await this.prisma.officeBranch.findUnique({ where: { id } });
      if (branch) {
        return await this.prisma.officeBranch.delete({ where: { id } });
      }
    } catch (e) {
      console.warn('Database offline, deleting branch in-memory');
    }

    const idx = this.inMemoryBranches.findIndex((b) => b.id === id);
    if (idx !== -1) {
      this.inMemoryBranches.splice(idx, 1);
      return { success: true };
    }
    throw new NotFoundException('Branch not found');
  }
}


