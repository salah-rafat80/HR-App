/* eslint-disable @typescript-eslint/no-unsafe-assignment, @typescript-eslint/no-unsafe-call, @typescript-eslint/no-unsafe-member-access, @typescript-eslint/no-unsafe-argument, @typescript-eslint/no-require-imports, @typescript-eslint/no-unused-vars */
import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as path from 'path';

import { PrismaService } from '../prisma/prisma.service';

export interface PushPayload {
  userId?: string;
  token: string;
  title: string;
  body: string;
  data?: Record<string, string>;
}

@Injectable()
export class NotificationService implements OnModuleInit {
  private readonly logger = new Logger(NotificationService.name);
  private isReady = false;
  private app: App | null = null;

  constructor(private readonly prisma: PrismaService) {}

  onModuleInit() {
    if (getApps().length) {
      this.app = getApps()[0];
      this.isReady = true;
      return;
    }

    try {
      let serviceAccount: any;
      let serviceAccountPath = 'ENVIRONMENT_VARIABLES';
      if (process.env.FIREBASE_CREDENTIALS) {
        try {
          serviceAccount = JSON.parse(process.env.FIREBASE_CREDENTIALS);
        } catch (_err) {
          throw new Error(
            'Failed to parse FIREBASE_CREDENTIALS environment variable as JSON',
          );
        }
      } else {
        const fs = require('fs');
        const possiblePaths = [
          path.resolve(
            __dirname,
            '../../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json',
          ),
          path.resolve(
            __dirname,
            '../../../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json',
          ),
          path.resolve(
            __dirname,
            '../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json',
          ),
          path.resolve(
            __dirname,
            '../../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json',
          ),
        ];

        serviceAccountPath = '';
        for (const p of possiblePaths) {
          if (fs.existsSync(p)) {
            serviceAccountPath = p;
            break;
          }
        }

        if (!serviceAccountPath) {
          throw new Error(
            `Could not find firebase-adminsdk credentials file in any of: ${possiblePaths.join(', ')}`,
          );
        }

        serviceAccount = require(serviceAccountPath);
      }

      this.app = initializeApp({
        credential: cert(serviceAccount),
        projectId: 'hr-app-18eef',
      });

      this.isReady = true;
      this.logger.log(
        `✅ Firebase Admin initialized using: ${serviceAccountPath} — Push Notifications ready`,
      );
    } catch (e) {
      this.logger.error(`❌ Firebase Admin init failed: ${e}`);
    }
  }

  // ── Send to single device ────────────────────────────────────────────────────

  async sendToDevice(payload: PushPayload): Promise<void> {
    if (payload.userId) {
      try {
        await this.prisma.notification.create({
          data: {
            userId: payload.userId,
            title: payload.title,
            body: payload.body,
            type: payload.data?.type || 'general',
            data: payload.data || {},
          },
        });
      } catch (err) {
        this.logger.error(`Failed to save notification to DB: ${err}`);
      }
    }

    if (!this.isReady || !this.app) {
      this.logger.warn('Push skipped — Firebase Admin not ready');
      return;
    }

    try {
      await getMessaging(this.app).send({
        token: payload.token,
        notification: {
          title: payload.title,
          body: payload.body,
        },
        data: payload.data ?? {},
        android: {
          priority: 'high',
          notification: {
            channelId: 'hr_app_high_importance_v2',
            sound: 'default',
            color: '#0B6E64',
          },
        },
      });
      this.logger.log(
        `Push sent: "${payload.title}" → ${payload.token.slice(0, 20)}...`,
      );
    } catch (err) {
      this.logger.error(`Push failed: ${err}`);
    }
  }

  // ── Convenience helpers ──────────────────────────────────────────────────────

  async notifyLeaveApproved(userId: string, token: string, employeeName: string, id: string) {
    return this.sendToDevice({
      userId,
      token,
      title: '✅ تم اعتماد إجازتك',
      body: `مرحباً ${employeeName}، تمت الموافقة على طلب إجازتك`,
      data: { type: 'leave_approved', id },
    });
  }

  async notifyLeaveStepApproved(
    userId: string,
    token: string,
    employeeName: string,
    id: string,
  ) {
    return this.sendToDevice({
      userId,
      token,
      title: '⏳ جاري مراجعة طلبك',
      body: `مرحباً ${employeeName}، تمت الموافقة على خطوة وطلبك في انتظار الموافقة التالية`,
      data: { type: 'leave_step_approved', id },
    });
  }

  async notifyLeaveRejected(userId: string, token: string, employeeName: string, id: string) {
    return this.sendToDevice({
      userId,
      token,
      title: '❌ تم رفض طلب الإجازة',
      body: `مرحباً ${employeeName}، تم رفض طلب إجازتك`,
      data: { type: 'leave_rejected', id },
    });
  }

  async notifyNewLeaveRequest(userId: string, token: string, employeeName: string, id: string) {
    return this.sendToDevice({
      userId,
      token,
      title: '📋 طلب إجازة جديد',
      body: `${employeeName} قدّم طلب إجازة يحتاج مراجعتك`,
      data: { type: 'leave_pending', id },
    });
  }

  async notifyOvertimeApproved(
    userId: string,
    token: string,
    employeeName: string,
    id?: string,
  ) {
    return this.sendToDevice({
      userId,
      token,
      title: '✅ تم اعتماد الأوفرتايم',
      body: `مرحباً ${employeeName}، تمت الموافقة على طلب الأوفرتايم`,
      data: { type: 'overtime_approved', ...(id ? { id } : {}) },
    });
  }

  async notifyKpiUpdated(userId: string, token: string, kpiTitle: string, id?: string) {
    return this.sendToDevice({
      userId,
      token,
      title: '🎯 تم تحديث KPI',
      body: `تم تحديث مؤشر "${kpiTitle}" الخاص بك`,
      data: { type: 'kpi_updated', ...(id ? { id } : {}) },
    });
  }

  async notifyNewAnnouncement(
    userIds: string[],
    tokens: string[],
    title: string,
    body: string,
    id?: string,
  ): Promise<{ successCount: number; failureCount: number }> {
    if (userIds.length > 0) {
      try {
        const data = userIds.map((uid) => ({
          userId: uid,
          title: `📢 إعلان جديد: ${title}`,
          body,
          type: 'new_announcement',
          data: id ? { id } : {},
        }));
        await this.prisma.notification.createMany({ data });
      } catch (err) {
        this.logger.error(`Failed to bulk save announcements to DB: ${err}`);
      }
    }
    if (!this.isReady || !this.app || !tokens.length) {
      return { successCount: 0, failureCount: tokens.length };
    }
    try {
      const response = await getMessaging(this.app).sendEachForMulticast({
        tokens,
        notification: {
          title: `📢 إعلان جديد: ${title}`,
          body,
        },
        data: { type: 'new_announcement', ...(id ? { id } : {}) },
        android: {
          priority: 'high',
          notification: {
            channelId: 'hr_app_high_importance_v2',
            sound: 'default',
            color: '#0B6E64',
          },
        },
      });
      return {
        successCount: response.successCount,
        failureCount: response.failureCount,
      };
    } catch (err) {
      this.logger.error(`Broadcast push failed: ${err}`);
      return { successCount: 0, failureCount: tokens.length };
    }
  }
}
