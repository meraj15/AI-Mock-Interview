import nodemailer, { Transporter } from 'nodemailer';
import { config } from '../config';
import { logger } from '../utils/logger';
import { AppError } from '../errors/AppError';

let transporter: Transporter | null = null;

/**
 * Lazily initialize and return the Brevo SMTP Nodemailer transporter.
 */
function getMailTransporter(): Transporter {
  if (transporter) return transporter;

  const host = (process.env.SMTP_HOST || config.email.smtpHost || 'smtp-relay.brevo.com').trim();
  const port = parseInt(process.env.SMTP_PORT || String(config.email.smtpPort) || '587', 10);
  const user = (process.env.SMTP_USER || config.email.smtpUser || '').trim();
  const pass = (process.env.SMTP_PASSWORD || config.email.smtpPassword || '').trim();

  if (!user || !pass) {
    logger.error('[EmailService] Brevo SMTP credentials (SMTP_USER / SMTP_PASSWORD) are not configured');
    throw new AppError(
      'Email service is not configured. Please set SMTP_USER and SMTP_PASSWORD in environment variables.',
      503,
      'EMAIL_NOT_CONFIGURED',
    );
  }

  transporter = nodemailer.createTransport({
    host,
    port,
    secure: port === 465, // true for 465 (SSL), false for 587 (STARTTLS)
    auth: {
      user,
      pass,
    },
  });

  return transporter;
}

/**
 * Build standard From address string: e.g. "Mock Interview <user@example.com>"
 */
function getFromAddress(): string {
  const fromEmail = (process.env.EMAIL_FROM || config.email.from || 'khanmeraj1542005@gmail.com').trim();
  const fromName = (process.env.EMAIL_FROM_NAME || config.email.fromName || 'Mock Interview').trim();
  return `"${fromName}" <${fromEmail}>`;
}

/**
 * Send an OTP verification email using Brevo SMTP.
 *
 * IMPORTANT: The raw OTP value is used only to build the email body here
 * and is never persisted or logged inside this function.
 */
export async function sendOtpEmail(
  to: string,
  fullName: string,
  otp: string,
): Promise<void> {
  const displayName = fullName.trim() || 'there';

  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Verify your Interview Coach account</title>
</head>
<body style="margin:0;padding:0;background:#0f0f12;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0f0f12;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0" style="background:#1a1a22;border-radius:16px;border:1px solid #2a2a35;overflow:hidden;">

          <!-- Header -->
          <tr>
            <td style="padding:32px 40px 24px;border-bottom:1px solid #2a2a35;">
              <p style="margin:0;font-size:13px;font-weight:600;color:#7c5cfc;letter-spacing:1.5px;text-transform:uppercase;">Interview Coach</p>
              <h1 style="margin:8px 0 0;font-size:22px;font-weight:700;color:#f0f0f5;">Verify your email address</h1>
            </td>
          </tr>

          <!-- Body -->
          <tr>
            <td style="padding:32px 40px;">
              <p style="margin:0 0 20px;font-size:14px;color:#9090a8;line-height:1.6;">
                Hi ${displayName},
              </p>
              <p style="margin:0 0 28px;font-size:14px;color:#9090a8;line-height:1.6;">
                Thanks for signing up! Use the code below to verify your email address and complete your registration.
              </p>

              <!-- OTP Box -->
              <div style="background:#0f0f12;border:1px solid #2a2a35;border-radius:12px;padding:28px;text-align:center;margin-bottom:28px;">
                <p style="margin:0 0 8px;font-size:11px;font-weight:600;color:#9090a8;letter-spacing:1.5px;text-transform:uppercase;">Your verification code</p>
                <p style="margin:0;font-size:40px;font-weight:700;color:#f0f0f5;letter-spacing:12px;">${otp}</p>
              </div>

              <p style="margin:0 0 8px;font-size:13px;color:#9090a8;line-height:1.6;">
                ⏱ This code expires in <strong style="color:#f0f0f5;">10 minutes</strong>.
              </p>
              <p style="margin:0;font-size:13px;color:#9090a8;line-height:1.6;">
                If you did not create an account, you can safely ignore this email.
              </p>
            </td>
          </tr>

          <!-- Footer -->
          <tr>
            <td style="padding:20px 40px;border-top:1px solid #2a2a35;">
              <p style="margin:0;font-size:11px;color:#5a5a72;text-align:center;">
                Interview Coach Team · This is an automated message, please do not reply.
              </p>
            </td>
          </tr>

        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `.trim();

  const text = `
Hi ${displayName},

Thanks for signing up! Use the code below to verify your email address and complete your registration:

${otp}

This code expires in 10 minutes.
If you did not create an account, you can safely ignore this email.

Thanks,
Interview Coach Team
  `.trim();

  try {
    const transport = getMailTransporter();
    const from = getFromAddress();

    const info = await transport.sendMail({
      from,
      to,
      subject: 'Verify your Interview Coach account',
      text,
      html,
    });

    logger.info('[EmailService] OTP email sent successfully via Brevo SMTP', { to, messageId: info.messageId });
  } catch (err) {
    if (err instanceof AppError) throw err;
    const msg = err instanceof Error ? err.message : 'Unexpected error';
    logger.error('[EmailService] Error sending OTP email via Brevo SMTP', { err: msg, to });
    throw new AppError(`Failed to send verification email: ${msg}`, 503, 'EMAIL_SEND_FAILED');
  }
}

/**
 * Send password recovery OTP email using Brevo SMTP.
 *
 * Subject: Reset your AI Mock Interview password
 */
export async function sendPasswordResetOtpEmail(
  to: string,
  otp: string,
  fullName?: string | null,
): Promise<void> {
  const greeting = fullName?.trim() ? `Hi ${fullName.trim()},` : 'Hi,';

  const html = `
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1.0"/>
  <title>Reset your Interview Coach password</title>
</head>
<body style="margin:0;padding:0;background:#0f0f12;font-family:'Segoe UI',Arial,sans-serif;">
  <table width="100%" cellpadding="0" cellspacing="0" style="background:#0f0f12;padding:40px 0;">
    <tr>
      <td align="center">
        <table width="480" cellpadding="0" cellspacing="0" style="background:#1a1a22;border-radius:16px;border:1px solid #2a2a35;overflow:hidden;">
          <tr>
            <td style="padding:32px 40px 24px;border-bottom:1px solid #2a2a35;">
              <p style="margin:0;font-size:13px;font-weight:600;color:#7c5cfc;letter-spacing:1.5px;text-transform:uppercase;">Interview Coach</p>
              <h1 style="margin:8px 0 0;font-size:22px;font-weight:700;color:#f0f0f5;">Reset your password</h1>
            </td>
          </tr>
          <tr>
            <td style="padding:32px 40px;">
              <p style="margin:0 0 16px;font-size:14px;color:#9090a8;line-height:1.6;">
                ${greeting}
              </p>
              <p style="margin:0 0 24px;font-size:14px;color:#9090a8;line-height:1.6;">
                We received a request to reset your Interview Coach password.
              </p>
              <div style="background:#0f0f12;border:1px solid #2a2a35;border-radius:12px;padding:24px;text-align:center;margin-bottom:24px;">
                <p style="margin:0 0 8px;font-size:11px;font-weight:600;color:#9090a8;letter-spacing:1.5px;text-transform:uppercase;">Your verification code</p>
                <p style="margin:0;font-size:38px;font-weight:700;color:#f0f0f5;letter-spacing:10px;">${otp}</p>
              </div>
              <p style="margin:0 0 12px;font-size:13px;color:#9090a8;line-height:1.6;">
                This code expires in <strong style="color:#f0f0f5;">10 minutes</strong>.
              </p>
              <p style="margin:0 0 20px;font-size:13px;color:#9090a8;line-height:1.6;">
                If you did not request a password reset, you can safely ignore this email.
              </p>
              <p style="margin:0;font-size:13px;color:#9090a8;line-height:1.6;">
                Thanks,<br/>
                <strong style="color:#f0f0f5;">Interview Coach</strong>
              </p>
            </td>
          </tr>
        </table>
      </td>
    </tr>
  </table>
</body>
</html>
  `.trim();

  const text = `
${greeting}

We received a request to reset your Interview Coach password.

Your verification code is:

${otp}

This code expires in 10 minutes.

If you did not request a password reset, you can safely ignore this email.

Thanks,
Interview Coach
  `.trim();

  try {
    const transport = getMailTransporter();
    const from = getFromAddress();

    const info = await transport.sendMail({
      from,
      to,
      subject: 'Reset your Interview Coach password',
      text,
      html,
    });

    logger.info('[EmailService] Password reset OTP sent successfully via Brevo SMTP', { to, messageId: info.messageId });
  } catch (err) {
    if (err instanceof AppError) throw err;
    const msg = err instanceof Error ? err.message : 'Unexpected error';
    logger.error('[EmailService] Error sending password reset email via Brevo SMTP', { err: msg, to });
    throw new AppError(`Failed to send password reset email: ${msg}`, 503, 'EMAIL_SEND_FAILED');
  }
}
