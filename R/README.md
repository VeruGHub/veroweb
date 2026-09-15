# Actualización de publicaciones

El flujo `.github/workflows/publish.yml` consulta Google Scholar cada lunes a
las 07:23 UTC, al cambiar main o al ejecutarlo manualmente en GitHub Actions.
Usa `scholar::get_publications()` con el perfil confirmado `mdktyS4AAAAJ`.
No necesita nuevas exportaciones BibTeX. El archivo original se conserva como fuente inicial.

La actualización modifica únicamente el bloque de Artículos. Mantiene el resto
de las secciones y guarda la lista generada en main antes de publicar gh-pages.
Si Scholar falla, devuelve una lista vacía o reduce el número de artículos,
el flujo se detiene: la web publicada y su última lista siguen disponibles.

Google Scholar no ofrece un tipo bibliográfico fiable. Se aceptan los títulos
revisados de `data/article-titles.txt` y nuevos trabajos en las revistas de
`data/article-journals.txt`. Las exclusiones de `data/excluded-titles.txt` tienen
prioridad, incluidos el capítulo, otros materiales y traducciones duplicadas.
Los trabajos en revistas nuevas o sin revista quedan en `data/scholar-pending.csv`
y en el artefacto de Actions para revisión. Para aprobarlos, añadir su título a
article-titles.txt o su revista a article-journals.txt. Esto no exige BibTeX.
Los nuevos libros y capítulos no se incorporan automáticamente a Libros.

Para activarlo, estos cambios deben estar en main y GitHub Actions debe tener
permiso de escritura (y poder hacer los commits según las reglas de la rama).
GitHub Pages debe servir la rama gh-pages. Los commits del bot no disparan otro
flujo: la publicación ocurre en esta misma ejecución.

Ejecutar localmente desde la raíz: `Rscript -e 'source("R/scholar_pubs.R"); scholar_pubs("mdktyS4AAAAJ")'`.
Requiere R y el paquete scholar. No se ha podido ejecutar R ni Quarto en el
entorno de preparación; la primera ejecución en GitHub debe verificar ambos.
