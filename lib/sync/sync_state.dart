//ESTA CLASE PERMMITE QUE EL ESTADO Y LA FECHA DE ÚLTIMA SINCRONIZACIÓN SEA ACCESIBLE EN CUALQUIER LUGAR DE LA APP
class SyncState {
  static DateTime? lastSyncTime;
  static bool isOnline = false;
}
