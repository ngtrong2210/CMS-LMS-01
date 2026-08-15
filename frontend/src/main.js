import { createApp } from 'vue'
import { createPinia } from 'pinia'
import 'bootstrap/dist/css/bootstrap.min.css'
import 'bootstrap-icons/font/bootstrap-icons.css'
import 'bootstrap'
import './assets/eduvers/css/style.css'
import './assets/eduvers/css/responsive.css'
import './assets/css/index.css'
import App from './App.vue'
import CmsPageActions from './components/navigation/CmsPageActions.vue'
import router from './router'

createApp(App).component('CmsPageActions', CmsPageActions).use(createPinia()).use(router).mount('#app')
