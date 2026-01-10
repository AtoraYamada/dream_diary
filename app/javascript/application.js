// Configure your import map in config/importmap.rb. Read more: https://github.com/rails/importmap-rails
import "common"

// Dynamic page-specific JS loading based on data-page attribute
document.addEventListener('DOMContentLoaded', () => {
    const pageIdentifier = document.body.dataset.page;

    if (pageIdentifier) {
        import(`pages/${pageIdentifier}`)
            .catch(error => {
                console.error(`[Application] Failed to load page JS: ${pageIdentifier}`, error);
            });
    }
});
