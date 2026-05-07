import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:rickandmorty/features/auth/presentation/providers/auth_provider.dart';
import 'package:rickandmorty/theme/text_theme.dart';
import 'package:rickandmorty/theme/theme_colors.dart';
import 'package:rickandmorty/widgets/liquidglass_container.dart';

class AuthScreen extends HookConsumerWidget {
  const AuthScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLogin = useState(true);
    final emailController = useTextEditingController();
    final passwordController = useTextEditingController();
    final usernameController = useTextEditingController();
    final isLoading = useState(false);
    final isDark = Theme.of(context).brightness == Brightness.dark;


    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF1A1A2E), const Color(0xFF16213E)]
                : [Colors.white, const Color(0xFFF0F2F5)],
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: GlassBox(
              padding: const EdgeInsets.all(32),
              opacity: isDark ? 0.1 : 0.05,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    isLogin.value ? 'С возвращением' : 'Создать аккаунт',
                    style: ThemeTextStyles.h1(isDark: isDark),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    isLogin.value
                        ? 'Войдите, чтобы продолжить'
                        : 'Присоединяйтесь к нашему сообществу',
                    style: ThemeTextStyles.bodyMedium(
                      isDark: isDark,
                      color: isDark ? Colors.white70 : Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (!isLogin.value) ...[
                    _buildTextField(
                      controller: usernameController,
                      hintText: 'Имя пользователя',
                      icon: Icons.person_outline,
                      isDark: isDark,
                    ),
                    const SizedBox(height: 16),
                  ],
                  _buildTextField(
                    controller: emailController,
                    hintText: 'Электронная почта',
                    icon: Icons.email_outlined,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: passwordController,
                    hintText: 'Пароль',
                    icon: Icons.lock_outline,
                    isDark: isDark,
                    isPassword: true,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: isLoading.value
                          ? null
                          : () async {
                              isLoading.value = true;
                              try {
                                if (isLogin.value) {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .login(
                                        emailController.text,
                                        passwordController.text,
                                      );
                                } else {
                                  await ref
                                      .read(authRepositoryProvider)
                                      .register(
                                        emailController.text,
                                        passwordController.text,
                                        usernameController.text,
                                      );
                                }
                                } catch (e) {
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(e.toString())),
                                    );
                                  }
                                } finally {
                                  if (context.mounted) {
                                    isLoading.value = false;
                                  }
                                }

                            },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: ThemeColors.blue,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 0,
                      ),
                      child: isLoading.value
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              isLogin.value ? 'Войти' : 'Зарегистрироваться',
                              style: ThemeTextStyles.bodyLarge(
                                color: Colors.white,
                              ),
                            ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextButton(
                    onPressed: () => isLogin.value = !isLogin.value,
                    child: Text(
                      isLogin.value
                          ? "Нет аккаунта? Зарегистрироваться"
                          : "Уже есть аккаунт? Войти",
                      style: ThemeTextStyles.bodySmall(color: ThemeColors.blue),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hintText,
    required IconData icon,
    required bool isDark,
    bool isPassword = false,
  }) {
    return GlassBox(
      opacity: isDark ? 0.05 : 0.03,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: TextField(
        controller: controller,
        obscureText: isPassword,
        style: ThemeTextStyles.bodyMedium(isDark: isDark),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: ThemeTextStyles.bodyMedium(
            color: isDark ? Colors.white38 : Colors.black38,
          ),
          icon: Icon(icon, color: isDark ? Colors.white54 : Colors.black54),
          border: InputBorder.none,
        ),
      ),
    );
  }
}
