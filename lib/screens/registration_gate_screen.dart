import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../services/timeline_controller.dart';
import '../theme/app_theme.dart';
import '../widgets/brand_logo_mark.dart';

class RegistrationGateScreen extends StatefulWidget {
  const RegistrationGateScreen({
    super.key,
    required this.controller,
  });

  final TimelineController controller;

  @override
  State<RegistrationGateScreen> createState() => _RegistrationGateScreenState();
}

class _RegistrationGateScreenState extends State<RegistrationGateScreen> {
  late final TextEditingController _phoneController;
  late final TextEditingController _codeController;
  bool _agreedToTerms = true;
  String? _lastPrefilledPendingPhoneNumber;

  @override
  void initState() {
    super.initState();
    _phoneController = TextEditingController();
    _codeController = TextEditingController();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: widget.controller,
      builder: (context, _) {
        final controller = widget.controller;

        if (controller.pendingPhoneNumber == null) {
          _lastPrefilledPendingPhoneNumber = null;
        } else if (controller.pendingPhoneNumber !=
            _lastPrefilledPendingPhoneNumber) {
          _phoneController.text = controller.pendingPhoneNumber!;
          _lastPrefilledPendingPhoneNumber = controller.pendingPhoneNumber;
        }

        return Scaffold(
          backgroundColor: AppTheme.background,
          body: DecoratedBox(
            decoration: const BoxDecoration(color: AppTheme.background),
            child: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 18, 20, 28),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight - 46,
                      ),
                      child: Column(
                        children: <Widget>[
                          const SizedBox(height: 8),
                          const BrandLogoMark(size: 64, radius: 14),
                          const SizedBox(height: 14),
                          Text(
                            '焦点时轴',
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(
                                  fontWeight: FontWeight.w800,
                                  height: 1.18,
                                ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            '手机号验证',
                            style: Theme.of(context)
                                .textTheme
                                .labelMedium
                                ?.copyWith(
                                  color: AppTheme.textSecondary,
                                  letterSpacing: 2.4,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          SizedBox(
                            height: constraints.maxHeight > 760 ? 40 : 18,
                          ),
                          Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 430),
                              child: _AuthPanel(
                                controller: controller,
                                phoneController: _phoneController,
                                codeController: _codeController,
                                agreedToTerms: _agreedToTerms,
                                onTermsChanged: (value) {
                                  setState(() {
                                    _agreedToTerms = value;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AuthPanel extends StatelessWidget {
  const _AuthPanel({
    required this.controller,
    required this.phoneController,
    required this.codeController,
    required this.agreedToTerms,
    required this.onTermsChanged,
  });

  final TimelineController controller;
  final TextEditingController phoneController;
  final TextEditingController codeController;
  final bool agreedToTerms;
  final ValueChanged<bool> onTermsChanged;

  @override
  Widget build(BuildContext context) {
    final resendText = controller.resendCountdown > 0
        ? '${controller.resendCountdown} 秒后可重新发送'
        : (controller.isSendingCode ? '发送中' : '发送验证码');
    final canSendCode =
        !controller.isSendingCode && controller.resendCountdown == 0;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        border: Border.all(color: AppTheme.border),
        boxShadow: const <BoxShadow>[
          BoxShadow(
            color: AppTheme.shadow,
            blurRadius: 30,
            offset: Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          const Wrap(
            spacing: 6,
            runSpacing: 6,
            children: <Widget>[
              _DialogPill(
                label: '登录以同步',
                foreground: AppTheme.accentStrong,
                background: AppTheme.accentSoft,
                border: AppTheme.accent,
              ),
              _DialogPill(
                label: '首次使用将自动创建账号',
                foreground: AppTheme.mintDeep,
                background: AppTheme.mintSoft,
                border: AppTheme.mint,
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            '继续保存你的关注',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  height: 1.18,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            '登录后可同步关注和专题，当前游客状态会尝试合并到账号内。',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                  height: 1.56,
                ),
          ),
          if (controller.errorMessage != null) ...<Widget>[
            const SizedBox(height: 14),
            _InlineNotice(message: controller.errorMessage!),
          ],
          const SizedBox(height: 18),
          TextField(
            controller: phoneController,
            keyboardType: TextInputType.phone,
            inputFormatters: <TextInputFormatter>[
              FilteringTextInputFormatter.digitsOnly,
              LengthLimitingTextInputFormatter(11),
            ],
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  height: 1.2,
                ),
            decoration: InputDecoration(
              labelText: '手机号',
              hintText: '请输入 11 位手机号',
              prefixIcon: const Icon(Icons.phone_iphone_rounded),
              filled: true,
              fillColor: AppTheme.surfaceMuted,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 15),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: AppTheme.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppTheme.accent,
                  width: 1.4,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          _VerificationCodeBoxes(controller: codeController),
          const SizedBox(height: 4),
          Center(
            child: TextButton(
              onPressed: canSendCode
                  ? () {
                      controller.sendVerificationCode(
                        phoneController.text,
                      );
                    }
                  : null,
              child: Text(resendText),
            ),
          ),
          if (controller.pendingPhoneNumber != null) ...<Widget>[
            const SizedBox(height: 10),
            Text(
              '验证码已发送至 ${controller.pendingPhoneNumber}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: AppTheme.textSecondary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ],
          if (controller.debugVerificationCode != null) ...<Widget>[
            const SizedBox(height: 14),
            _InlineNotice(
              message:
                  '演示环境短信验证码：${controller.debugVerificationCode}\n接入真实短信平台后，这里将不再显示验证码。',
              tone: AppTheme.highlight,
              background: AppTheme.highlightSoft,
            ),
          ],
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.fromLTRB(4, 2, 8, 2),
            decoration: BoxDecoration(
              color: AppTheme.surfaceMuted,
              borderRadius: BorderRadius.circular(AppTheme.radiusControl),
              border: Border.all(color: AppTheme.border),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Checkbox(
                  value: agreedToTerms,
                  activeColor: AppTheme.accentStrong,
                  onChanged: (value) {
                    onTermsChanged(value ?? false);
                  },
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(
                      '我已阅读并同意《用户协议》和《隐私政策》，接受通过短信发送确认验证码。',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: AppTheme.textSecondary,
                            height: 1.5,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: controller.isVerifyingCode
                  ? null
                  : () {
                      if (!agreedToTerms) {
                        controller.showError('请先勾选同意协议后再登录。');
                        return;
                      }
                      controller.verifySmsCode(
                        rawPhoneNumber: phoneController.text,
                        smsCode: codeController.text,
                      );
                    },
              style: FilledButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 18),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppTheme.radiusControl),
                ),
              ),
              child: controller.isVerifyingCode
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppTheme.background,
                      ),
                    )
                  : const Text('验证并同步'),
            ),
          ),
        ],
      ),
    );
  }
}

class _DialogPill extends StatelessWidget {
  const _DialogPill({
    required this.label,
    required this.foreground,
    required this.background,
    required this.border,
  });

  final String label;
  final Color foreground;
  final Color background;
  final Color border;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusPill),
        border: Border.all(color: border.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
              color: foreground,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
      ),
    );
  }
}

class _VerificationCodeBoxes extends StatelessWidget {
  const _VerificationCodeBoxes({
    required this.controller,
  });

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 50,
      child: Stack(
        children: <Widget>[
          ValueListenableBuilder<TextEditingValue>(
            valueListenable: controller,
            builder: (context, value, _) {
              final code = value.text;
              return Row(
                children: List<Widget>.generate(6, (index) {
                  final digit = index < code.length ? code[index] : '';
                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 5 ? 0 : 7),
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: digit.isEmpty
                              ? AppTheme.surfaceMuted
                              : AppTheme.accentSoft,
                          borderRadius:
                              BorderRadius.circular(AppTheme.radiusControl),
                          border: Border.all(
                            color: digit.isEmpty
                                ? AppTheme.border
                                : AppTheme.accent.withValues(alpha: 0.22),
                          ),
                        ),
                        child: Center(
                          child: Text(
                            digit,
                            style: Theme.of(context)
                                .textTheme
                                .titleLarge
                                ?.copyWith(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w900,
                                  height: 1,
                                ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              );
            },
          ),
          Positioned.fill(
            child: TextField(
              controller: controller,
              keyboardType: TextInputType.number,
              inputFormatters: <TextInputFormatter>[
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              autofocus: false,
              showCursor: false,
              style: const TextStyle(color: Colors.transparent),
              decoration: const InputDecoration(
                border: InputBorder.none,
                enabledBorder: InputBorder.none,
                focusedBorder: InputBorder.none,
                filled: false,
                contentPadding: EdgeInsets.zero,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InlineNotice extends StatelessWidget {
  const _InlineNotice({
    required this.message,
    this.tone = AppTheme.danger,
    this.background = AppTheme.highlightSoft,
  });

  final String message;
  final Color tone;
  final Color background;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppTheme.radiusControl),
        border: Border.all(color: tone.withValues(alpha: 0.16)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Icon(Icons.info_outline_rounded, size: 18, color: tone),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textPrimary,
                    height: 1.45,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
