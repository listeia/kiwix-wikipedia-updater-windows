ACTUALIZADOR DE WIKIPEDIA EN ESPAÑOL PARA KIWIX — WINDOWS 10/11
Estado: versión inicial en pruebas.

QUÉ HACE
- Comprueba semanalmente el catálogo oficial de Kiwix.
- Detecta la versión más reciente de wikipedia_es_all.
- Solo descarga si existe una versión nueva.
- Reanuda una descarga interrumpida.
- Conserva el archivo anterior hasta que la descarga nueva termina.
- Después elimina las versiones antiguas y deja una sola.
- Guarda un registro en actualizacion-kiwix.log.

INSTALACIÓN
1. Extrae todo el contenido del ZIP en una carpeta.
2. Haz doble clic en CONFIGURAR_KIWIX.cmd.
3. Elige:
   1 = mini
   2 = nopic (recomendada)
   3 = maxi
4. Elige la carpeta de destino o acepta la propuesta.
5. Decide si quieres iniciar la primera descarga en ese momento.

USARLO CON KIWIX JS PWA
1. Abre Kiwix JS PWA.
2. En Configuración, elige abrir un archivo ZIM o seleccionar una carpeta de archivos.
3. Selecciona la carpeta configurada y abre el archivo wikipedia_es_all_...zim.
4. Para comprobar que funciona sin Internet, desconecta el Wi-Fi y abre varios artículos.

IMPORTANTE
- Kiwix no ofrece actualizaciones incrementales: cada edición nueva se descarga completa.
- Mientras descarga una versión nueva, necesitas espacio para la antigua y la nueva.
- La tarea se ejecuta los domingos a las 03:00 y también puede arrancar después si el equipo estaba apagado.
- Windows normalmente no iniciará la tarea estando solo con batería.
- El actualizador usa curl.exe, incluido normalmente en Windows 10/11.

DESINSTALACIÓN
- Ejecuta DESINSTALAR_KIWIX.cmd.
- No se borrarán los archivos .zim.
