# Fotografías de los proyectos

Las imágenes SVG son ejemplos con la paleta Gredos; no representan los proyectos reales.

Para añadir tus fotografías:

1. Guarda cada fotografía JPG, PNG o WebP en esta carpeta, preferiblemente con un nombre sin espacios.
2. En `Projects.qmd`, cambia la ruta de la imagen del proyecto. Por ejemplo, cambia `images/projects/quevadis.svg` por `images/projects/quevadis.jpg`.
3. Cambia también `fig-alt` por una descripción breve de la fotografía real.
4. Renderiza la web para comprobar el resultado.

| Proyecto | Imagen provisional |
| --- | --- |
| Futures4Forests | futures4forests.svg |
| QueVADIS | quevadis.svg |
| Sesgos en la restauración forestal | forest-restoration-biases.svg |
| ForestAssembly | forestassembly.svg |

Las imágenes se muestran en proporción 4:3, sin deformarse. Si quieres que se vea la fotografía completa sin recorte, cambia `object-fit: cover` por `object-fit: contain` en la regla `.project-entry .project-image` de `styles.css`.
