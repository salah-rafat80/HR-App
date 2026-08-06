import { Injectable, Logger, OnModuleInit } from '@nestjs/common';
import { initializeApp, getApps, cert, App } from 'firebase-admin/app';
import { getMessaging } from 'firebase-admin/messaging';
import * as path from 'path';

export interface PushPayload {
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

  onModuleInit() {
    if (getApps().length) {
      this.app = getApps()[0];
      this.isReady = true;
      return;
    }

    try {
      const fs = require('fs');
      const possiblePaths = [
        // 1. Backend root when running from dist (3 levels up)
        path.resolve(__dirname, '../../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json'),
        // 2. Monorepo root when running from dist (4 levels up)
        path.resolve(__dirname, '../../../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json'),
        // 3. Backend root when running from src (2 levels up)
        path.resolve(__dirname, '../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json'),
        // 4. Monorepo root when running from src (3 levels up)
        path.resolve(__dirname, '../../../hr-app-18eef-firebase-adminsdk-fbsvc-0e03f6ece7.json'),
      ];

      let serviceAccountPath = '';
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

      // eslint-disable-next-line @typescript-eslint/no-require-imports
      const serviceAccount = require(serviceAccountPath);

      this.app = initializeApp({
        credential: cert(serviceAccount),
        projectId: 'hr-app-18eef',
      });

      this.isReady = true;
      this.logger.log(`✅ Firebase Admin initialized using: ${serviceAccountPath} — Push Notifications ready`);
    } catch (e) {
      this.logger.error(`❌ Firebase Admin init failed: ${e}`);
    }
  }

  // ── Send to single device ────────────────────────────────────────────────────

  async sendToDevice(payload: PushPayload): Promise<void> {
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
            channelId: 'hr_app_high_importance',
            sound: 'default',
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

  async notifyLeaveApproved(token: string, employeeName: string) {
    return this.sendToDevice({
      token,
      title: '✅ تم اعتماد إجازتك',
      body: `مرحباً ${employeeName}، تمت الموافقة على طلب إجازتك`,
      data: { type: 'leave_approved' },
    });
  }

  async notifyLeaveRejected(token: string, employeeName: string) {
    return this.sendToDevice({
      token,
      title: '❌ تم رفض طلب الإجازة',
      body: `مرحباً ${employeeName}، تم رفض طلب إجازتك`,
      data: { type: 'leave_rejected' },
    });
  }

  async notifyNewLeaveRequest(token: string, employeeName: string) {
    return this.sendToDevice({
      token,
      title: '📋 طلب إجازة جديد',
      body: `${employeeName} قدّم طلب إجازة يحتاج مراجعتك`,
      data: { type: 'leave_pending' },
    });
  }

  async notifyOvertimeApproved(token: string, employeeName: string) {
    return this.sendToDevice({
      token,
      title: '✅ تم اعتماد الأوفرتايم',
      body: `مرحباً ${employeeName}، تمت الموافقة على طلب الأوفرتايم`,
      data: { type: 'overtime_approved' },
    });
  }

  async notifyKpiUpdated(token: string, kpiTitle: string) {
    return this.sendToDevice({
      token,
      title: '🎯 تم تحديث KPI',
      body: `تم تحديث مؤشر "${kpiTitle}" الخاص بك`,
      data: { type: 'kpi_updated' },
    });
  }
}
