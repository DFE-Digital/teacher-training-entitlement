import SwaggerUIBundle from 'swagger-ui-dist/swagger-ui-bundle'

const path = document.getElementById('swagger-ui').dataset.path

document.addEventListener('DOMContentLoaded', () => {
  SwaggerUIBundle({
    url: `${path}/swagger.yaml?v=${new Date().getTime()}`,
    dom_id: '#swagger-ui',
    deepLinking: true,
    presets: [SwaggerUIBundle.presets.apis, SwaggerUIBundle.SwaggerUIStandalonePreset],
    plugins: [SwaggerUIBundle.plugins.DownloadUrl],
  });
});
