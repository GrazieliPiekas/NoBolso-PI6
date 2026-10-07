import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Notificações locais de orçamento (RF05). Nenhum servidor envolvido.
/// Em plataformas sem suporte (desktop de desenvolvimento, testes) vira no-op.
class NotificacaoService {
  NotificacaoService._();
  static final NotificacaoService instance = NotificacaoService._();

  final _plugin = FlutterLocalNotificationsPlugin();
  bool _pronto = false;

  static const _canal = AndroidNotificationDetails(
    'orcamentos',
    'Orçamentos',
    channelDescription: 'Avisos quando um orçamento chega a 50%, 80% ou 100%',
    importance: Importance.defaultImportance,
    priority: Priority.defaultPriority,
  );

  bool get _suportado => !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  Future<void> inicializar() async {
    if (!_suportado) return;
    try {
      await _plugin.initialize(
        settings: const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
          iOS: DarwinInitializationSettings(
            requestAlertPermission: false,
            requestBadgePermission: false,
            requestSoundPermission: false,
          ),
        ),
      );
      _pronto = true;
    } catch (e) {
      debugPrint('Notificações indisponíveis: $e');
    }
  }

  /// Pede permissão (Android 13+ / iOS). Chamado quando o usuário cria um orçamento.
  Future<void> pedirPermissao() async {
    if (!_pronto) return;
    await _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >()
        ?.requestNotificationsPermission();
    await _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >()
        ?.requestPermissions(alert: true, sound: true);
  }

  Future<void> mostrar({
    required int id,
    required String titulo,
    required String corpo,
  }) async {
    if (!_pronto) return;
    await _plugin.show(
      id: id,
      title: titulo,
      body: corpo,
      notificationDetails: const NotificationDetails(
        android: _canal,
        iOS: DarwinNotificationDetails(),
      ),
    );
  }
}
