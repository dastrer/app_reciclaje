import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../../data/database_helper.dart';
import '../../viewmodels/login_viewmodel.dart';
import '../../utils/constants.dart';

class UsuariosScreen extends StatefulWidget {
  const UsuariosScreen({super.key});

  @override
  State<UsuariosScreen> createState() => _UsuariosScreenState();
}

class _UsuariosScreenState extends State<UsuariosScreen> {
  final DatabaseHelper _db = DatabaseHelper.instance;
  final TextEditingController _busquedaCtrl = TextEditingController();

  bool _loading = true;
  String? _error;

  List<_RolItem> _roles = [];
  List<_UsuarioItem> _usuarios = [];
  List<_UsuarioItem> _filtrados = [];

  String _filtroRol = 'TODOS'; // nombre rol o 'TODOS'
  String _filtroEstado = 'TODOS'; // 'TODOS' | 'ACTIVO' | 'RESTRINGIDO'

  @override
  void initState() {
    super.initState();
    _cargarTodo();
    _busquedaCtrl.addListener(_aplicarFiltros);
  }

  @override
  void dispose() {
    _busquedaCtrl.dispose();
    super.dispose();
  }

  // ─────────────────────────────────────────
  // 📥 CARGA
  // ─────────────────────────────────────────
  Future<void> _cargarTodo() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final roles = await _cargarRoles();
      final usuarios = await _cargarUsuarios();
      if (!mounted) return;
      setState(() {
        _roles = roles;
        _usuarios = usuarios;
        _filtrados = usuarios;
        _loading = false;
      });
      _aplicarFiltros();
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Error al cargar usuarios: $e';
        _loading = false;
      });
    }
  }

  Future<List<_RolItem>> _cargarRoles() async {
    final rows = await _db.rawQuery(
      'SELECT id, nombre, descripcion FROM rol ORDER BY id ASC',
    );
    return rows
        .map((r) => _RolItem(
              id: r['id'] as int,
              nombre: (r['nombre'] as String?) ?? '',
              descripcion: (r['descripcion'] as String?) ?? '',
            ))
        .toList();
  }

  Future<List<_UsuarioItem>> _cargarUsuarios() async {
    final rows = await _db.rawQuery('''
      SELECT
        u.id,
        u.rol_id,
        r.nombre      AS rol_nombre,
        u.nombre_usuario,
        u.nombres,
        u.ap_paterno,
        u.ap_materno,
        u.correo,
        u.estado,
        u.avatar_ruta,
        u.fecha_creacion
      FROM usuario u
      JOIN rol r ON r.id = u.rol_id
      ORDER BY u.id ASC
    ''');

    return rows.map((r) {
      final nombres = (r['nombres'] as String?) ?? '';
      final apPat = (r['ap_paterno'] as String?) ?? '';
      final apMat = (r['ap_materno'] as String?) ?? '';
      final full = '$nombres $apPat $apMat'.trim();

      return _UsuarioItem(
        id: r['id'] as int,
        rolId: r['rol_id'] as int,
        rolNombre: (r['rol_nombre'] as String?) ?? '',
        nombreUsuario: (r['nombre_usuario'] as String?) ?? '',
        nombreCompleto: full,
        correo: (r['correo'] as String?) ?? '',
        estado: (r['estado'] as String?) ?? 'ACTIVO',
        avatarRuta: r['avatar_ruta'] as String?,
        fechaCreacion: (r['fecha_creacion'] as String?) ?? '',
      );
    }).toList();
  }

  // ─────────────────────────────────────────
  // 🔎 FILTROS
  // ─────────────────────────────────────────
  void _aplicarFiltros() {
    final q = _busquedaCtrl.text.trim().toLowerCase();
    final res = _usuarios.where((u) {
      final coincideQ = q.isEmpty ||
          u.nombreCompleto.toLowerCase().contains(q) ||
          u.nombreUsuario.toLowerCase().contains(q) ||
          u.correo.toLowerCase().contains(q);
      final coincideRol =
          _filtroRol == 'TODOS' || u.rolNombre.toUpperCase() == _filtroRol;
      final coincideEstado =
          _filtroEstado == 'TODOS' || u.estado.toUpperCase() == _filtroEstado;
      return coincideQ && coincideRol && coincideEstado;
    }).toList();
    setState(() => _filtrados = res);
  }

  // ─────────────────────────────────────────
  // ➕ CREAR / ✏️ EDITAR
  // ─────────────────────────────────────────
  Future<void> _abrirFormulario({_UsuarioItem? usuario}) async {
    final resultado = await showModalBottomSheet<_FormUsuarioResult>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _FormUsuarioSheet(
        roles: _roles,
        usuario: usuario,
        db: _db,
      ),
    );

    if (resultado == null) return;

    if (usuario == null) {
      // Crear
      try {
        await _db.crearUsuario(
          rolId: resultado.rolId,
          nombreUsuario: resultado.nombreUsuario,
          nombres: resultado.nombres,
          apPaterno: resultado.apPaterno,
          apMaterno: resultado.apMaterno,
          correo: resultado.correo,
          contrasena: resultado.contrasena,
          estado: resultado.estado,
        );
        _toast('Usuario creado correctamente');
      } catch (e) {
        _toast('Error al crear: $e', error: true);
        return;
      }
    } else {
      // Editar
      try {
        await _db.rawUpdate('''
          UPDATE usuario SET
            rol_id = ?,
            nombre_usuario = ?,
            nombres = ?,
            ap_paterno = ?,
            ap_materno = ?,
            correo = ?,
            contrasena = ?,
            estado = ?,
            fecha_actualizacion = ?
          WHERE id = ?
        ''', [
          resultado.rolId,
          resultado.nombreUsuario,
          resultado.nombres,
          resultado.apPaterno,
          resultado.apMaterno,
          resultado.correo,
          resultado.contrasena,
          resultado.estado,
          DateTime.now().toIso8601String(),
          usuario.id,
        ]);
        _toast('Usuario actualizado');
      } catch (e) {
        _toast('Error al actualizar: $e', error: true);
        return;
      }
    }

    await _cargarTodo();
  }

  // ─────────────────────────────────────────
  // 🗑️ ELIMINAR
  // ─────────────────────────────────────────
  Future<void> _eliminar(_UsuarioItem u) async {
    final yo = context.read<LoginViewModel>().usuarioActual;
    if (yo != null && yo.id == u.id) {
      _toast('No puedes eliminar tu propia cuenta', error: true);
      return;
    }

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Eliminar usuario'),
        content: Text(
          '¿Seguro que deseas eliminar a "${u.nombreCompleto}" '
          '(@${u.nombreUsuario})?\n\n'
          'Esta acción borrará también sus estadísticas, evaluaciones, '
          'inventario, tickets, etc.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _db.rawDelete('DELETE FROM usuario WHERE id = ?', [u.id]);
      _toast('Usuario eliminado');
      await _cargarTodo();
    } catch (e) {
      _toast('Error al eliminar: $e', error: true);
    }
  }

  // ─────────────────────────────────────────
  // 🔒 CAMBIAR ESTADO
  // ─────────────────────────────────────────
  Future<void> _cambiarEstado(_UsuarioItem u) async {
    final yo = context.read<LoginViewModel>().usuarioActual;
    if (yo != null && yo.id == u.id) {
      _toast('No puedes cambiar el estado de tu propia cuenta',
          error: true);
      return;
    }

    final nuevoEstado = u.estado == 'ACTIVO' ? 'RESTRINGIDO' : 'ACTIVO';

    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(
          nuevoEstado == 'RESTRINGIDO'
              ? 'Restringir usuario'
              : 'Activar usuario',
        ),
        content: Text(
          nuevoEstado == 'RESTRINGIDO'
              ? 'El usuario "${u.nombreCompleto}" no podrá iniciar sesión '
                  'mientras esté restringido.'
              : 'El usuario "${u.nombreCompleto}" podrá iniciar sesión nuevamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: nuevoEstado == 'RESTRINGIDO'
                  ? AppColors.error
                  : AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.pop(context, true),
            child: Text(
              nuevoEstado == 'RESTRINGIDO' ? 'Restringir' : 'Activar',
            ),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      await _db.rawUpdate('''
        UPDATE usuario
        SET estado = ?, fecha_actualizacion = ?
        WHERE id = ?
      ''', [
        nuevoEstado,
        DateTime.now().toIso8601String(),
        u.id,
      ]);
      _toast(
        nuevoEstado == 'RESTRINGIDO'
            ? 'Usuario restringido'
            : 'Usuario activado',
      );
      await _cargarTodo();
    } catch (e) {
      _toast('Error al cambiar estado: $e', error: true);
    }
  }

  void _toast(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  // ─────────────────────────────────────────
  // 🖼️ UI
  // ─────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_error != null) {
      return _buildError();
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _abrirFormulario(),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add),
        label: const Text(
          'Nuevo usuario',
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
        ),
      ),
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: _cargarTodo,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            _buildEncabezado(),
            const SizedBox(height: 14),
            _buildBuscadorYFiltros(),
            const SizedBox(height: 14),
            if (_filtrados.isEmpty)
              _buildVacio()
            else
              ..._filtrados.map((u) => _buildUsuarioTile(u)),
          ],
        ),
      ),
    );
  }

  Widget _buildError() {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 80),
        Icon(Icons.error_outline, size: 64, color: AppColors.error),
        const SizedBox(height: 16),
        Text(
          _error!,
          textAlign: TextAlign.center,
          style: AppTextStyles.body.copyWith(
            color: AppColors.error,
            fontSize: 15,
          ),
        ),
        const SizedBox(height: 16),
        Center(
          child: ElevatedButton.icon(
            onPressed: _cargarTodo,
            icon: const Icon(Icons.refresh),
            label: const Text('Reintentar'),
          ),
        ),
      ],
    );
  }

  Widget _buildEncabezado() {
    final total = _usuarios.length;
    final activos = _usuarios.where((u) => u.estado == 'ACTIVO').length;
    final restringidos = total - activos;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primary.withOpacity(0.75)],
        ),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.manage_accounts,
                  color: Colors.white, size: 36),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Gestión de Usuarios',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white,
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Crea, edita y administra cuentas',
                      style: AppTextStyles.body.copyWith(
                        color: Colors.white70,
                        fontSize: 13.5,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                onPressed: _cargarTodo,
                icon: const Icon(Icons.refresh, color: Colors.white),
                tooltip: 'Actualizar',
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              _statBadge('Total', '$total', Colors.white),
              const SizedBox(width: 8),
              _statBadge('Activos', '$activos', const Color(0xFFB9F6CA)),
              const SizedBox(width: 8),
              _statBadge(
                'Restringidos',
                '$restringidos',
                const Color(0xFFFFCDD2),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(String label, String valor, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.15),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTextStyles.body.copyWith(
                color: color.withOpacity(0.9),
                fontSize: 12,
              ),
            ),
            Text(
              valor,
              style: AppTextStyles.body.copyWith(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBuscadorYFiltros() {
    final rolesFiltro = ['TODOS', ..._roles.map((r) => r.nombre)];
    return Column(
      children: [
        TextField(
          controller: _busquedaCtrl,
          decoration: InputDecoration(
            hintText: 'Buscar por nombre, usuario o correo...',
            hintStyle: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 14,
            ),
            prefixIcon: const Icon(Icons.search),
            filled: true,
            fillColor: Colors.white,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: AppColors.textSecondary.withOpacity(0.2),
              ),
            ),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _dropdownFiltro(
                label: 'Rol',
                valorActual: _filtroRol,
                opciones: rolesFiltro,
                onChanged: (v) {
                  setState(() => _filtroRol = v ?? 'TODOS');
                  _aplicarFiltros();
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _dropdownFiltro(
                label: 'Estado',
                valorActual: _filtroEstado,
                opciones: const ['TODOS', 'ACTIVO', 'RESTRINGIDO'],
                onChanged: (v) {
                  setState(() => _filtroEstado = v ?? 'TODOS');
                  _aplicarFiltros();
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _dropdownFiltro({
    required String label,
    required String valorActual,
    required List<String> opciones,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.2),
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          isExpanded: true,
          value: valorActual,
          hint: Text(label),
          style: AppTextStyles.body.copyWith(
            fontSize: 14,
            color: AppColors.textPrimary,
          ),
          items: opciones
              .map((e) => DropdownMenuItem(
                    value: e,
                    child: Text(
                      e,
                      style: AppTextStyles.body.copyWith(fontSize: 14),
                    ),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildVacio() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48),
      child: Column(
        children: [
          Icon(Icons.people_outline,
              size: 64, color: AppColors.textSecondary.withOpacity(0.5)),
          const SizedBox(height: 12),
          Text(
            'No se encontraron usuarios',
            style: AppTextStyles.body.copyWith(
              color: AppColors.textSecondary,
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUsuarioTile(_UsuarioItem u) {
    final yo = context.watch<LoginViewModel>().usuarioActual;
    final esYo = yo != null && yo.id == u.id;
    final activo = u.estado == 'ACTIVO';
    final colorRol = _colorPorRol(u.rolNombre);
    final colorEstado = activo ? AppColors.success : AppColors.error;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColors.textSecondary.withOpacity(0.15),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: colorRol.withOpacity(0.15),
                  backgroundImage:
                      u.avatarRuta != null ? AssetImage(u.avatarRuta!) : null,
                  child: u.avatarRuta == null
                      ? Text(
                          u.nombreCompleto.isNotEmpty
                              ? u.nombreCompleto[0].toUpperCase()
                              : '?',
                          style: AppTextStyles.body.copyWith(
                            color: colorRol,
                            fontWeight: FontWeight.bold,
                            fontSize: 18,
                          ),
                        )
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              u.nombreCompleto.isEmpty
                                  ? u.nombreUsuario
                                  : u.nombreCompleto,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.body.copyWith(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: AppColors.textPrimary,
                              ),
                            ),
                          ),
                          if (esYo) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 6,
                                vertical: 2,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'TÚ',
                                style: AppTextStyles.body.copyWith(
                                  color: Colors.white,
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      Text(
                        '@${u.nombreUsuario}',
                        style: AppTextStyles.body.copyWith(
                          fontSize: 12.5,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                _chip(Icons.email, u.correo, AppColors.textSecondary),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                _chip(
                  _iconoPorRol(u.rolNombre),
                  u.rolNombre,
                  colorRol,
                ),
                const SizedBox(width: 6),
                _chip(
                  activo ? Icons.check_circle : Icons.block,
                  activo ? 'ACTIVO' : 'RESTRINGIDO',
                  colorEstado,
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _abrirFormulario(usuario: u),
                    icon: const Icon(Icons.edit, size: 16),
                    label: const Text('Editar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: esYo ? null : () => _cambiarEstado(u),
                    icon: Icon(
                      activo ? Icons.lock : Icons.lock_open,
                      size: 16,
                    ),
                    label: Text(activo ? 'Restringir' : 'Activar'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: activo
                          ? const Color(0xFFEF6C00)
                          : AppColors.success,
                      side: BorderSide(
                        color: (activo
                                ? const Color(0xFFEF6C00)
                                : AppColors.success)
                            .withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: esYo ? null : () => _eliminar(u),
                  icon: Icon(
                    Icons.delete_outline,
                    color: esYo
                        ? AppColors.textSecondary.withOpacity(0.4)
                        : AppColors.error,
                  ),
                  tooltip: 'Eliminar',
                  style: IconButton.styleFrom(
                    backgroundColor:
                        AppColors.error.withOpacity(esYo ? 0.05 : 0.1),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _chip(IconData icono, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 13, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: AppTextStyles.body.copyWith(
              fontSize: 11.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _colorPorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return const Color(0xFF6A1B9A);
      case 'MAESTRO':
      case 'DOCENTE':
        return const Color(0xFF1565C0);
      case 'PADRE':
        return const Color(0xFFEF6C00);
      case 'NIÑO':
      case 'NINO':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
  }

  IconData _iconoPorRol(String rol) {
    switch (rol.toUpperCase()) {
      case 'ADMIN':
        return Icons.admin_panel_settings;
      case 'MAESTRO':
      case 'DOCENTE':
        return Icons.school;
      case 'PADRE':
        return Icons.family_restroom;
      case 'NIÑO':
      case 'NINO':
        return Icons.child_care;
      default:
        return Icons.person;
    }
  }
}

// ==========================================
// 📦 MODELOS PRIVADOS
// ==========================================
class _RolItem {
  final int id;
  final String nombre;
  final String descripcion;
  const _RolItem({
    required this.id,
    required this.nombre,
    required this.descripcion,
  });
}

class _UsuarioItem {
  final int id;
  final int rolId;
  final String rolNombre;
  final String nombreUsuario;
  final String nombreCompleto;
  final String correo;
  final String estado;
  final String? avatarRuta;
  final String fechaCreacion;

  const _UsuarioItem({
    required this.id,
    required this.rolId,
    required this.rolNombre,
    required this.nombreUsuario,
    required this.nombreCompleto,
    required this.correo,
    required this.estado,
    required this.avatarRuta,
    required this.fechaCreacion,
  });
}

class _FormUsuarioResult {
  final int rolId;
  final String nombreUsuario;
  final String nombres;
  final String? apPaterno;
  final String? apMaterno;
  final String correo;
  final String contrasena;
  final String estado;

  const _FormUsuarioResult({
    required this.rolId,
    required this.nombreUsuario,
    required this.nombres,
    required this.apPaterno,
    required this.apMaterno,
    required this.correo,
    required this.contrasena,
    required this.estado,
  });
}

// ==========================================
// 🧩 FORMULARIO MODAL
// ==========================================
class _FormUsuarioSheet extends StatefulWidget {
  final List<_RolItem> roles;
  final _UsuarioItem? usuario;
  final DatabaseHelper db;

  const _FormUsuarioSheet({
    required this.roles,
    required this.db,
    this.usuario,
  });

  @override
  State<_FormUsuarioSheet> createState() => _FormUsuarioSheetState();
}

class _FormUsuarioSheetState extends State<_FormUsuarioSheet> {
  final _formKey = GlobalKey<FormState>();

  // ─── Regex reutilizables ───
  // Letras unicode (incluye tildes y ñ/Ñ), espacios internos.
  // No permite números ni símbolos, ni espacios al inicio/fin,
  // ni dobles espacios seguidos.
  static final RegExp _reSoloLetras = RegExp(
    r"^[a-zA-ZÁÉÍÓÚáéíóúÑñÜü]+(?: [a-zA-ZÁÉÍÓÚáéíóúÑñÜü]+)*$",
  );

  // Username: alfanumérico y guion bajo, debe empezar con letra.
  static final RegExp _reUsername = RegExp(r'^[a-zA-Z][a-zA-Z0-9_]{2,29}$');

  // Correo estándar razonable.
  static final RegExp _reCorreo = RegExp(
    r"^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$",
  );

  // Contraseña: al menos 1 letra y 1 número.
  static final RegExp _rePassTieneLetra =
      RegExp(r'[A-Za-zÁÉÍÓÚáéíóúÑñÜü]');
  static final RegExp _rePassTieneNumero = RegExp(r'[0-9]');

  late final TextEditingController _nombreUsuarioCtrl;
  late final TextEditingController _nombresCtrl;
  late final TextEditingController _apPaternoCtrl;
  late final TextEditingController _apMaternoCtrl;
  late final TextEditingController _correoCtrl;
  late final TextEditingController _contrasenaCtrl;

  int? _rolIdSeleccionado;
  String _estadoSeleccionado = 'ACTIVO';
  bool _mostrarPass = false;
  bool _guardando = false;

  bool get _esEdicion => widget.usuario != null;

  @override
  void initState() {
    super.initState();
    final u = widget.usuario;
    _nombreUsuarioCtrl =
        TextEditingController(text: u?.nombreUsuario ?? '');
    _nombresCtrl = TextEditingController(
      text: u != null ? u.nombreCompleto.split(' ').first : '',
    );
    _apPaternoCtrl = TextEditingController();
    _apMaternoCtrl = TextEditingController();
    _correoCtrl = TextEditingController(text: u?.correo ?? '');
    _contrasenaCtrl = TextEditingController();

    _rolIdSeleccionado = u?.rolId ??
        (widget.roles.isNotEmpty ? widget.roles.first.id : null);
    _estadoSeleccionado = u?.estado ?? 'ACTIVO';

    if (u != null) {
      _precargarPartesNombre();
    }
  }

  Future<void> _precargarPartesNombre() async {
    final u = widget.usuario;
    if (u == null) return;
    final rows = await widget.db.rawQuery(
      'SELECT nombres, ap_paterno, ap_materno FROM usuario WHERE id = ?',
      [u.id],
    );
    if (rows.isEmpty) return;
    final r = rows.first;
    if (!mounted) return;
    setState(() {
      _nombresCtrl.text = (r['nombres'] as String?) ?? '';
      _apPaternoCtrl.text = (r['ap_paterno'] as String?) ?? '';
      _apMaternoCtrl.text = (r['ap_materno'] as String?) ?? '';
    });
  }

  @override
  void dispose() {
    _nombreUsuarioCtrl.dispose();
    _nombresCtrl.dispose();
    _apPaternoCtrl.dispose();
    _apMaternoCtrl.dispose();
    _correoCtrl.dispose();
    _contrasenaCtrl.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;
    if (_rolIdSeleccionado == null) {
      _snack('Selecciona un rol', error: true);
      return;
    }

    setState(() => _guardando = true);

    // Sanitización
    final nombreUsuarioSan =
        _nombreUsuarioCtrl.text.trim().toLowerCase();
    final correoSan = _correoCtrl.text.trim().toLowerCase();

    // Verificar unicidad de username y correo
    final existentes = await widget.db.rawQuery('''
      SELECT id, nombre_usuario, correo FROM usuario
      WHERE (LOWER(nombre_usuario) = ? OR LOWER(correo) = ?)
      ${_esEdicion ? 'AND id != ?' : ''}
    ''', [
      nombreUsuarioSan,
      correoSan,
      if (_esEdicion) widget.usuario!.id,
    ]);

    if (existentes.isNotEmpty) {
      final r = existentes.first;
      final mismoUser =
          (r['nombre_usuario'] as String?)?.toLowerCase() == nombreUsuarioSan;
      if (!mounted) return;
      setState(() => _guardando = false);
      _snack(
        mismoUser
            ? 'Ese nombre de usuario ya está en uso'
            : 'Ese correo ya está registrado',
        error: true,
      );
      return;
    }

    if (!mounted) return;
    Navigator.pop(
      context,
      _FormUsuarioResult(
        rolId: _rolIdSeleccionado!,
        nombreUsuario: nombreUsuarioSan,
        nombres: _nombresCtrl.text.trim(),
        apPaterno: _apPaternoCtrl.text.trim().isEmpty
            ? null
            : _apPaternoCtrl.text.trim(),
        apMaterno: _apMaternoCtrl.text.trim().isEmpty
            ? null
            : _apMaternoCtrl.text.trim(),
        correo: correoSan,
        contrasena: _contrasenaCtrl.text,
        estado: _estadoSeleccionado,
      ),
    );
  }

  void _snack(String msg, {bool error = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: error ? AppColors.error : AppColors.success,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final maxHeight = MediaQuery.of(context).size.height * 0.9;

    return Container(
      constraints: BoxConstraints(maxHeight: maxHeight),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 12,
          bottom: bottomInset + 20,
        ),
        child: Form(
          key: _formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.textSecondary.withOpacity(0.3),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        _esEdicion
                            ? Icons.edit
                            : Icons.person_add_alt_1,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _esEdicion ? 'Editar usuario' : 'Nuevo usuario',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 19,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            _esEdicion
                                ? 'Modifica los datos del usuario'
                                : 'Completa los campos para crear la cuenta',
                            style: AppTextStyles.body.copyWith(
                              fontSize: 13,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),

                // ─── Rol ───
                _label('Rol del usuario *'),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: widget.roles.map((r) {
                    final sel = _rolIdSeleccionado == r.id;
                    return ChoiceChip(
                      label: Text(
                        r.nombre,
                        style: AppTextStyles.body.copyWith(
                          fontSize: 13,
                          fontWeight:
                              sel ? FontWeight.bold : FontWeight.normal,
                          color: sel ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      selected: sel,
                      selectedColor: AppColors.primary,
                      backgroundColor: Colors.white,
                      side: BorderSide(
                        color: sel
                            ? AppColors.primary
                            : AppColors.textSecondary.withOpacity(0.3),
                      ),
                      onSelected: (_) {
                        setState(() => _rolIdSeleccionado = r.id);
                      },
                    );
                  }).toList(),
                ),
                const SizedBox(height: 16),

                // ─── Nombres ───
                _label('Nombres *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nombresCtrl,
                  maxLength: 60,
                  textCapitalization: TextCapitalization.words,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'[0-9]')),
                  ],
                  decoration:
                      _inputDeco('Ej. Ana María').copyWith(counterText: ''),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Ingresa los nombres';
                    if (t.length < 2) return 'Mínimo 2 caracteres';
                    if (t.length > 60) return 'Máximo 60 caracteres';
                    if (!_reSoloLetras.hasMatch(t)) {
                      return 'Solo letras y espacios (sin números ni símbolos)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ─── Apellidos ───
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Apellido paterno'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _apPaternoCtrl,
                            maxLength: 40,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(
                                  RegExp(r'[0-9]')),
                            ],
                            decoration: _inputDeco('Ej. López')
                                .copyWith(counterText: ''),
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return null;
                              if (t.length > 40) {
                                return 'Máximo 40 caracteres';
                              }
                              if (!_reSoloLetras.hasMatch(t)) {
                                return 'Solo letras y espacios';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _label('Apellido materno'),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _apMaternoCtrl,
                            maxLength: 40,
                            textCapitalization: TextCapitalization.words,
                            inputFormatters: [
                              FilteringTextInputFormatter.deny(
                                  RegExp(r'[0-9]')),
                            ],
                            decoration: _inputDeco('Ej. García')
                                .copyWith(counterText: ''),
                            validator: (v) {
                              final t = v?.trim() ?? '';
                              if (t.isEmpty) return null;
                              if (t.length > 40) {
                                return 'Máximo 40 caracteres';
                              }
                              if (!_reSoloLetras.hasMatch(t)) {
                                return 'Solo letras y espacios';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // ─── Username ───
                _label('Nombre de usuario *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _nombreUsuarioCtrl,
                  maxLength: 30,
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(
                        RegExp(r'[a-zA-Z0-9_]')),
                  ],
                  decoration:
                      _inputDeco('Ej. ana_lopez').copyWith(counterText: ''),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Ingresa un nombre de usuario';
                    if (t.length < 3) return 'Mínimo 3 caracteres';
                    if (t.length > 30) return 'Máximo 30 caracteres';
                    if (t.contains(' ')) return 'No debe contener espacios';
                    if (!RegExp(r'^[a-zA-Z]').hasMatch(t)) {
                      return 'Debe empezar con una letra';
                    }
                    if (!_reUsername.hasMatch(t)) {
                      return 'Solo letras, números y guion bajo';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ─── Correo ───
                _label('Correo electrónico *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _correoCtrl,
                  maxLength: 100,
                  keyboardType: TextInputType.emailAddress,
                  autofillHints: const [AutofillHints.email],
                  textInputAction: TextInputAction.next,
                  inputFormatters: [
                    FilteringTextInputFormatter.deny(RegExp(r'\s')),
                  ],
                  decoration: _inputDeco('usuario@correo.com')
                      .copyWith(counterText: ''),
                  validator: (v) {
                    final t = v?.trim() ?? '';
                    if (t.isEmpty) return 'Ingresa un correo';
                    if (t.length > 100) return 'Máximo 100 caracteres';
                    if (t.contains(' ')) return 'No debe contener espacios';
                    if (!_reCorreo.hasMatch(t)) return 'Correo inválido';
                    if (t.contains('..')) return 'Correo inválido';
                    final partes = t.split('@');
                    if (partes.length != 2) return 'Correo inválido';
                    if (!partes[1].contains('.')) return 'Correo inválido';
                    return null;
                  },
                ),
                const SizedBox(height: 12),

                // ─── Contraseña ───
                _label(_esEdicion
                    ? 'Nueva contraseña (dejar vacío para no cambiar)'
                    : 'Contraseña *'),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _contrasenaCtrl,
                  obscureText: !_mostrarPass,
                  maxLength: 40,
                  autofillHints: const [AutofillHints.newPassword],
                  decoration: _inputDeco('••••••').copyWith(
                    counterText: '',
                    suffixIcon: IconButton(
                      icon: Icon(
                        _mostrarPass
                            ? Icons.visibility_off
                            : Icons.visibility,
                        color: AppColors.textSecondary,
                      ),
                      onPressed: () =>
                          setState(() => _mostrarPass = !_mostrarPass),
                    ),
                  ),
                  validator: (v) {
                    final t = v ?? '';
                    if (_esEdicion && t.isEmpty) return null;
                    if (t.isEmpty) return 'Ingresa una contraseña';
                    if (t.length < 6) return 'Mínimo 6 caracteres';
                    if (t.length > 40) return 'Máximo 40 caracteres';
                    if (t.contains(' ')) return 'No debe contener espacios';
                    if (!_rePassTieneLetra.hasMatch(t)) {
                      return 'Debe contener al menos una letra';
                    }
                    if (!_rePassTieneNumero.hasMatch(t)) {
                      return 'Debe contener al menos un número';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // ─── Estado ───
                _label('Estado de la cuenta'),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: _chipEstado(
                        'ACTIVO',
                        Icons.check_circle,
                        AppColors.success,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _chipEstado(
                        'RESTRINGIDO',
                        Icons.block,
                        AppColors.error,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // ─── Acciones ───
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed:
                            _guardando ? null : () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                          side: BorderSide(
                            color: AppColors.textSecondary
                                .withOpacity(0.4),
                          ),
                          foregroundColor: AppColors.textSecondary,
                        ),
                        child: const Text(
                          'Cancelar',
                          style: TextStyle(fontSize: 15),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: _guardando ? null : _guardar,
                        icon: _guardando
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _esEdicion
                                    ? Icons.save
                                    : Icons.person_add,
                                size: 18,
                              ),
                        label: Text(
                          _guardando
                              ? 'Guardando...'
                              : (_esEdicion
                                  ? 'Guardar cambios'
                                  : 'Crear usuario'),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          padding:
                              const EdgeInsets.symmetric(vertical: 14),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _label(String txt) => Text(
        txt,
        style: AppTextStyles.body.copyWith(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      );

  InputDecoration _inputDeco(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: AppTextStyles.body.copyWith(
          color: AppColors.textSecondary.withOpacity(0.7),
          fontSize: 14,
        ),
        filled: true,
        fillColor: const Color(0xFFF7F9F7),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withOpacity(0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: AppColors.primary, width: 1.6),
        ),
      );

  Widget _chipEstado(String valor, IconData icono, Color color) {
    final sel = _estadoSeleccionado == valor;
    return GestureDetector(
      onTap: () => setState(() => _estadoSeleccionado = valor),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: sel ? color.withOpacity(0.12) : Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: sel
                ? color
                : AppColors.textSecondary.withOpacity(0.25),
            width: sel ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icono,
              size: 18,
              color: sel ? color : AppColors.textSecondary,
            ),
            const SizedBox(width: 6),
            Text(
              valor,
              style: AppTextStyles.body.copyWith(
                fontSize: 12.5,
                fontWeight: FontWeight.bold,
                color: sel ? color : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}