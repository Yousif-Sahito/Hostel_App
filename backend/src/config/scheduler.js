import cron from 'node-cron';
import { sendBatchUnpaidBillNotifications } from '../services/notification.service.js';
import { logger } from '../utils/logger.js';

// Schedule unpaid bill notifications to run daily at 8 AM (server time)
export const scheduleUnpaidBillNotifications = () => {
  cron.schedule('0 8 * * *', async () => {
    logger.info('Running scheduled unpaid bill notification job...');
    try {
      await sendBatchUnpaidBillNotifications();
      logger.info('Unpaid bill notification job completed successfully');
    } catch (error) {
      logger.error('Error in unpaid bill notification job:', error);
    }
  });

  logger.info('Unpaid bill notification scheduler initialized (runs daily at 8 AM)');
};

export default scheduleUnpaidBillNotifications;
