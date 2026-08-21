<template>
  <section>
    <header class="d-flex flex-wrap justify-content-between align-items-end gap-3 mb-4">
      <div>
        <h1 class="page-title mb-1">Thư viện video</h1>
        <p class="page-subtitle mb-0">
          Video mặc định chỉ tác giả nhìn thấy; có thể chia sẻ cho giáo viên khác hoặc toàn trường.
        </p>
      </div>
      <CmsPageActions>
        <button class="btn btn-action-create" @click="openUpload">
          <i class="bi bi-cloud-arrow-up"></i> Thêm video
        </button>
      </CmsPageActions>
    </header>

    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>

    <div class="app-card filter-card mb-3">
      <div class="filter-grid">
        <label class="filter-field search-field">
          <span>Tìm nhanh</span>
          <div class="search-box">
            <i class="bi bi-search"></i
            ><input v-model.trim="search" class="form-control" placeholder="Tên video, tên file hoặc tác giả..." />
          </div>
        </label>
        <label class="filter-field">
          <span>Quyền truy cập</span>
          <select v-model="accessFilter" class="form-select">
            <option value="ALL">Tất cả được phép xem</option>
            <option value="MINE">Video của tôi</option>
            <option value="SHARED">Được chia sẻ với tôi</option>
            <option value="SCHOOL">Chia sẻ toàn trường</option>
          </select>
        </label>
        <label class="filter-field">
          <span>Nguồn video</span>
          <select v-model="sourceFilter" class="form-select">
            <option value="ALL">Tất cả nguồn</option>
            <option value="LOCAL">Video tải lên</option>
            <option value="YOUTUBE">Liên kết YouTube</option>
          </select>
        </label>
        <label class="filter-field">
          <span>Tình trạng dùng</span>
          <select v-model="usageFilter" class="form-select">
            <option value="ALL">Tất cả</option>
            <option value="USED">Đang dùng</option>
            <option value="UNUSED">Chưa sử dụng</option>
          </select>
        </label>
        <label class="filter-field">
          <span>Trạng thái</span>
          <select v-model="statusFilter" class="form-select">
            <option value="ALL">Tất cả</option>
            <option value="ACTIVE">Hoạt động</option>
            <option value="INACTIVE">Tạm ẩn</option>
          </select>
        </label>
      </div>
      <div class="filter-footer">
        <span
          ><i class="bi bi-collection-play"></i> Tìm thấy <strong>{{ items.length }}</strong> video</span
        >
        <button v-if="hasFilters" class="btn btn-action-cancel btn-sm" @click="clearFilters">
          <i class="bi bi-arrow-counterclockwise"></i> Xóa bộ lọc
        </button>
      </div>
    </div>

    <div class="app-card p-2">
      <div class="table-responsive">
        <table class="table align-middle mb-0">
          <thead>
            <tr>
              <th>Video</th>
              <th>Quyền truy cập</th>
              <th>Thời lượng /<br />Sử dụng</th>
              <th>Người tạo<br />/ Ngày tạo</th>
              <th class="text-end">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, index) in items" :key="item.id">
              <td>
                <div class="video-name">
                  <span class="video-thumb" :style="{ backgroundImage: `url(${thumbnailFor(item, index)})` }"
                    ><i class="bi bi-play-fill"></i
                  ></span>
                  <div>
                    <strong>{{ item.title }}</strong>
                    <span :class="['video-source-badge', item.sourceType.toLowerCase()]">
                      <i :class="['bi', item.sourceType === 'YOUTUBE' ? 'bi-youtube' : 'bi-file-play']"></i>
                      {{ item.sourceType === 'YOUTUBE' ? 'YouTube' : 'Tải lên' }}
                    </span>
                    <small>{{ item.originalFileName || item.videoUrl || 'Chưa có nguồn video' }}</small>
                  </div>
                </div>
              </td>
              <td>
                <span :class="['access-badge', `access-${item.accessType.toLowerCase()}`]"
                  ><i :class="['bi', accessIcon(item.accessType)]"></i>{{ accessLabel(item) }}</span
                >
              </td>
              <td>
                <div class="video-usage-summary">
                  <strong><i class="bi bi-clock"></i>{{ formatTime(item.durationSeconds) }}</strong>
                  <span class="badge badge-soft-primary">{{ item.usageCount }} bài học</span>
                </div>
              </td>
              <td>
                <div class="video-creator-summary">
                  <strong class="author-name">{{ item.createdByName }}</strong>
                  <span><i class="bi bi-calendar3"></i>{{ formatDate(item.createdAt) }}</span>
                </div>
              </td>
              <td class="text-end action-cell">
                <div class="video-action-group">
                  <button
                    v-if="item.canEdit"
                    class="btn btn-action-edit btn-sm edit-button"
                    title="Sửa thông tin video"
                    @click="openEdit(item)"
                  >
                    <i class="bi bi-pencil-square"></i><span>Thông tin</span>
                  </button>
                  <RouterLink
                    v-if="item.firstVideoId && item.canOpenEditor"
                    class="btn btn-action-view btn-sm"
                    :to="`/cms/videos/${item.firstVideoId}/editor`"
                    :title="item.canEdit ? 'Biên tập video tương tác' : 'Xem video đã khóa và nhân bản'"
                    ><i :class="['bi', item.canEdit ? 'bi-sliders' : 'bi-eye']"></i
                    ><span>{{ item.canEdit ? 'Soạn tương tác' : 'Xem video' }}</span></RouterLink
                  >
                  <button
                    v-if="item.canDuplicate"
                    class="btn btn-action-copy btn-sm"
                    :disabled="duplicatingId === item.id"
                    title="Nhân bản video"
                    @click="duplicateVideo(item)"
                  >
                    <span v-if="duplicatingId === item.id" class="spinner-border spinner-border-sm"></span
                    ><i v-else class="bi bi-copy"></i><span>Nhân bản</span>
                  </button>
                  <button
                    v-if="item.canShare"
                    class="btn btn-action-share btn-sm share-button"
                    title="Quản lý chia sẻ"
                    @click="openShare(item)"
                  >
                    <i class="bi bi-share"></i><span>Chia sẻ</span>
                  </button>
                  <button
                    v-if="item.isOwner || item.canDelete"
                    class="btn btn-action-delete btn-sm"
                    :disabled="!item.canDelete"
                    :title="item.canDelete ? 'Xóa video' : 'Video đang được sử dụng nên chưa thể xóa'"
                    @click="remove(item)"
                  >
                    <i class="bi bi-trash"></i><span>Xóa</span>
                  </button>
                </div>
              </td>
            </tr>
            <tr v-if="!loading && !items.length">
              <td colspan="5" class="text-center text-secondary py-5">
                <i class="bi bi-search d-block fs-2 mb-2"></i>Không có video phù hợp với bộ lọc.
              </td>
            </tr>
          </tbody>
        </table>
      </div>
      <div v-if="loading" class="text-center p-4"><span class="spinner-border text-brand"></span></div>
    </div>

    <div v-if="uploadModal" class="modal-mask" @click.self="uploadModal = false">
      <form class="app-card upload-modal" @submit.prevent="save">
        <div class="modal-heading">
          <div>
            <small>{{ form.id ? 'Cập nhật đồng bộ video' : 'Video của tôi' }}</small>
            <h2>{{ form.id ? 'Sửa video chưa có kết quả' : 'Thêm video vào thư viện' }}</h2>
            <p>
              {{
                form.id
                  ? 'Video chưa có điểm hoặc câu trả lời nên có thể sửa trực tiếp. Tất cả bài học đang dùng sẽ được đồng bộ.'
                  : 'Video mới được đặt ở chế độ riêng tư. Bạn có thể chia sẻ sau khi lưu.'
              }}
            </p>
          </div>
          <button type="button" class="btn-close" @click="uploadModal = false"></button>
        </div>
        <div class="video-source-picker" role="group" aria-label="Chọn nguồn video">
          <button
            type="button"
            :class="['video-source-option', { active: form.sourceType === 'LOCAL' }]"
            @click="changeSourceType('LOCAL')"
          >
            <i class="bi bi-cloud-arrow-up"></i
            ><span><strong>Tải video lên</strong><small>MP4, WebM, OGV hoặc MOV</small></span>
          </button>
          <button
            type="button"
            :class="['video-source-option', { active: form.sourceType === 'YOUTUBE' }]"
            @click="changeSourceType('YOUTUBE')"
          >
            <i class="bi bi-youtube"></i
            ><span><strong>Liên kết YouTube</strong><small>Dùng video công khai hoặc không công khai</small></span>
          </button>
        </div>
        <label v-if="form.sourceType === 'LOCAL' && !form.videoUrl" class="drop-zone" :class="{ disabled: uploading }"
          ><i class="bi bi-cloud-arrow-up"></i
          ><strong>{{ uploading ? `Đang tải lên ${uploadProgress}%` : 'Chọn file video' }}</strong
          ><span>MP4, WebM, OGV hoặc MOV; file lưu trong project.</span
          ><input
            class="visually-hidden"
            type="file"
            accept="video/mp4,video/webm,video/ogg,video/quicktime"
            :disabled="uploading"
            @change="upload"
        /></label>
        <div v-else-if="form.sourceType === 'LOCAL'" class="video-preview">
          <video
            ref="metadataVideo"
            :src="playbackUrl"
            controls
            preload="metadata"
            @loadedmetadata="readDuration"
          ></video
          ><label class="btn btn-action-upload btn-sm mt-2" :class="{ disabled: uploading }"
            ><i class="bi bi-arrow-repeat"></i> {{ uploading ? `Đang tải ${uploadProgress}%` : 'Thay file video'
            }}<input
              class="visually-hidden"
              type="file"
              accept="video/mp4,video/webm,video/ogg,video/quicktime"
              :disabled="uploading"
              @change="upload"
          /></label>
        </div>
        <div v-else class="youtube-source-panel">
          <label class="form-label" for="youtube-url">Liên kết YouTube</label>
          <div class="input-group">
            <span class="input-group-text"><i class="bi bi-youtube"></i></span>
            <input
              id="youtube-url"
              v-model.trim="youtubeInput"
              class="form-control"
              type="url"
              placeholder="https://www.youtube.com/watch?v=..."
              @input="applyYouTubeUrl"
            />
          </div>
          <p v-if="youtubeInput && !youtubeValid" class="youtube-validation">
            <i class="bi bi-exclamation-circle"></i> Liên kết YouTube chưa hợp lệ.
          </p>
          <YouTubeVideoPlayer
            v-if="youtubeValid"
            class="youtube-library-preview"
            :source="form.videoUrl"
            @ready="onYouTubeReady"
          />
        </div>
        <div class="row g-3 mt-1">
          <div class="col-md-6">
            <label class="form-label">Tên video</label
            ><input v-model.trim="form.title" class="form-control" required maxlength="500" />
          </div>
          <div class="col-md-3">
            <label class="form-label">Thời lượng (giây)</label
            ><input v-model.number="form.durationSeconds" class="form-control" type="number" min="1" required />
          </div>
          <div class="col-md-3">
            <label class="form-label">Trạng thái</label
            ><select v-model="form.status" class="form-select">
              <option value="ACTIVE">Hoạt động</option>
              <option value="INACTIVE">Tạm ẩn</option>
            </select>
          </div>
          <div class="col-12">
            <label class="form-label">{{
              form.sourceType === 'YOUTUBE' ? 'Đường dẫn YouTube chuẩn hóa' : 'URL tương đối trong project'
            }}</label
            ><input v-model="form.videoUrl" class="form-control" readonly required />
          </div>
        </div>
        <section v-if="form.id" class="version-panel sync-panel">
          <div class="version-panel-heading">
            <div>
              <span class="version-badge"><i class="bi bi-arrow-repeat"></i> Đồng bộ an toàn</span>
              <h3>{{ form.usageCount }} bài học sẽ nhận nội dung mới</h3>
              <p>Tiến độ xem chưa có điểm sẽ được đặt lại để học viên bắt đầu đúng nội dung vừa cập nhật.</p>
            </div>
            <span class="usage-total">Chưa có kết quả</span>
          </div>
        </section>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="uploadModal = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving || uploading || !sourceIsValid">
            <span v-if="saving" class="spinner-border spinner-border-sm me-1"></span
            ><i v-else :class="['bi', form.id ? 'bi-arrow-repeat' : 'bi-check-lg']"></i>
            {{ form.id ? 'Lưu và đồng bộ' : 'Lưu vào thư viện' }}
          </button>
        </div>
      </form>
    </div>

    <div v-if="shareModal" class="modal-mask" @click.self="closeShare">
      <form class="app-card upload-modal share-modal" @submit.prevent="saveSharing">
        <div class="modal-heading">
          <div>
            <small>Quyền truy cập video</small>
            <h2>Chia sẻ “{{ shareForm.title }}”</h2>
            <p>Chỉ cấp quyền nhìn thấy và sử dụng trong bài học; người nhận không thể xóa hoặc chia sẻ lại.</p>
          </div>
          <button type="button" class="btn-close" @click="closeShare"></button>
        </div>
        <div v-if="sharingLoading" class="text-center p-5"><span class="spinner-border text-brand"></span></div>
        <template v-else>
          <div class="scope-options">
            <label :class="['scope-option', { selected: shareForm.shareScope === 'PRIVATE' }]"
              ><input v-model="shareForm.shareScope" type="radio" value="PRIVATE" /><i class="bi bi-lock"></i
              ><span><strong>Chỉ mình tôi</strong><small>Chỉ tác giả và quản trị viên nhìn thấy.</small></span></label
            >
            <label :class="['scope-option', { selected: shareForm.shareScope === 'SELECTED' }]"
              ><input v-model="shareForm.shareScope" type="radio" value="SELECTED" /><i class="bi bi-person-check"></i
              ><span
                ><strong>Giáo viên được chọn</strong><small>Chia sẻ cho một hoặc nhiều giáo viên cụ thể.</small></span
              ></label
            >
            <label :class="['scope-option', { selected: shareForm.shareScope === 'SCHOOL' }]"
              ><input v-model="shareForm.shareScope" type="radio" value="SCHOOL" /><i class="bi bi-building"></i
              ><span
                ><strong>Toàn trường</strong><small>Mọi tài khoản giáo viên đều có thể sử dụng.</small></span
              ></label
            >
          </div>
          <div v-if="shareForm.shareScope === 'SELECTED'" class="teacher-picker">
            <div class="teacher-picker-head">
              <label
                ><i class="bi bi-search"></i
                ><input
                  v-model.trim="teacherSearch"
                  class="form-control"
                  placeholder="Tìm tên, mã hoặc email giáo viên..." /></label
              ><span
                >Đã chọn <strong>{{ shareForm.teacherIds.length }}</strong></span
              >
            </div>
            <div class="teacher-list">
              <label v-for="teacher in filteredTeachers" :key="teacher.id" class="teacher-option"
                ><input v-model="shareForm.teacherIds" type="checkbox" :value="teacher.id" /><span
                  class="teacher-avatar"
                  >{{ initials(teacher.fullName) }}</span
                ><span
                  ><strong>{{ teacher.fullName }}</strong
                  ><small>{{ teacher.teacherCode }} · {{ teacher.email }}</small></span
                ></label
              >
              <p v-if="!filteredTeachers.length" class="text-center text-secondary m-0 py-4">
                Không có giáo viên phù hợp.
              </p>
            </div>
          </div>
        </template>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="closeShare"><i class="bi bi-x-lg"></i> Hủy</button
          ><button
            class="btn btn-action-share"
            :disabled="
              sharingLoading || sharingSaving || (shareForm.shareScope === 'SELECTED' && !shareForm.teacherIds.length)
            "
          >
            <span v-if="sharingSaving" class="spinner-border spinner-border-sm me-1"></span
            ><i v-else class="bi bi-share me-1"></i>Lưu chia sẻ
          </button>
        </div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref, watch } from 'vue'
import { useRouter } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import { resolveApiAssetUrl } from '../../api/apiConfig'
import YouTubeVideoPlayer from '../../components/video/YouTubeVideoPlayer.vue'
import { useListViewState } from '../../composables/useListViewState'
import { confirmDialog } from '../../utils/confirmDialog'
import { formatInteractionTime } from '../../utils/learningRules'
import {
  canonicalYouTubeUrl,
  extractYouTubeVideoId,
  normalizeVideoSource,
  youtubeThumbnailUrl
} from '../../utils/videoSources'

const items = ref([]),
  search = ref(''),
  accessFilter = ref('ALL'),
  sourceFilter = ref('ALL'),
  usageFilter = ref('ALL'),
  statusFilter = ref('ALL'),
  loading = ref(true)
const uploadModal = ref(false),
  uploading = ref(false),
  saving = ref(false),
  duplicatingId = ref(0),
  uploadProgress = ref(0),
  metadataVideo = ref(null)
const shareModal = ref(false),
  sharingLoading = ref(false),
  sharingSaving = ref(false),
  shareTeachers = ref([]),
  teacherSearch = ref('')
const message = ref(''),
  messageType = ref('success'),
  youtubeInput = ref(''),
  form = reactive(blank()),
  shareForm = reactive({ assetId: 0, title: '', shareScope: 'PRIVATE', teacherIds: [] })
const router = useRouter()
useListViewState('cms-videos', { search, accessFilter, sourceFilter, usageFilter, statusFilter })
const playbackUrl = computed(() => resolveApiAssetUrl(form.videoUrl)),
  youtubeValid = computed(() => Boolean(extractYouTubeVideoId(youtubeInput.value || form.videoUrl))),
  sourceIsValid = computed(() =>
    form.sourceType === 'YOUTUBE'
      ? Boolean(extractYouTubeVideoId(youtubeInput.value || form.videoUrl))
      : Boolean(form.videoUrl)
  ),
  pick = (source, ...names) =>
    names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null),
  formatTime = formatInteractionTime
const hasFilters = computed(
  () =>
    Boolean(search.value) ||
    [accessFilter.value, sourceFilter.value, usageFilter.value, statusFilter.value].some((value) => value !== 'ALL')
)
const filteredTeachers = computed(() => {
  const term = teacherSearch.value.toLocaleLowerCase('vi')
  return shareTeachers.value.filter(
    (t) => !term || `${t.fullName} ${t.email} ${t.teacherCode}`.toLocaleLowerCase('vi').includes(term)
  )
})
const fallbackThumbnails = [
  new URL('../../assets/eduvers/images/courses/course-list-img-1.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-list-img-2.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-list-img-3.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-list-img-4.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-list-img-5.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-1-1.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-1-2.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-1-3.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-1-4.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-2-1.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-2-2.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-2-3.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-3-1.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-3-2.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-3-3.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-3-4.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-3-5.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/courses-3-6.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-details-img-1.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-details-client-img-1.jpg', import.meta.url).href,
  new URL('../../assets/eduvers/images/courses/course-details-Instructor-img.jpg', import.meta.url).href
]

let timer
watch([search, accessFilter, sourceFilter, usageFilter, statusFilter], () => {
  clearTimeout(timer)
  timer = setTimeout(load, 250)
})
onMounted(load)
function blank() {
  return {
    id: 0,
    title: '',
    sourceType: 'LOCAL',
    videoUrl: '',
    posterUrl: '',
    durationSeconds: 60,
    originalFileName: '',
    fileSize: 0,
    mimeType: '',
    status: 'ACTIVE',
    changeSummary: '',
    lessonIds: [],
    usageCount: 0
  }
}
async function load() {
  loading.value = true
  try {
    const rows = await axiosClient.get('/video-library', {
      params: {
        search: search.value || undefined,
        access: accessFilter.value,
        source: sourceFilter.value,
        usage: usageFilter.value,
        status: statusFilter.value,
        _fresh: Date.now()
      }
    })
    items.value = (Array.isArray(rows) ? rows : []).map((row) => ({
      id: Number(pick(row, 'Id', 'id')),
      title: pick(row, 'Title', 'title'),
      sourceType: normalizeVideoSource(pick(row, 'SourceType', 'sourceType')),
      videoUrl: pick(row, 'VideoUrl', 'videoUrl') || '',
      posterUrl: pick(row, 'PosterUrl', 'posterUrl') || '',
      originalFileName: pick(row, 'OriginalFileName', 'originalFileName') || '',
      fileSize: Number(pick(row, 'FileSize', 'fileSize') || 0),
      mimeType: pick(row, 'MimeType', 'mimeType') || '',
      durationSeconds: Number(pick(row, 'DurationSeconds', 'durationSeconds') || 0),
      status: pick(row, 'Status', 'status') || 'ACTIVE',
      usageCount: Number(pick(row, 'UsageCount', 'usageCount') || 0),
      createdByName: pick(row, 'CreatedByName', 'createdByName') || '',
      createdAt: pick(row, 'CreatedAt', 'createdAt'),
      firstVideoId: Number(pick(row, 'FirstVideoId', 'firstVideoId') || 0),
      shareScope: pick(row, 'ShareScope', 'shareScope') || 'PRIVATE',
      accessType: pick(row, 'AccessType', 'accessType') || 'OWNER',
      sharedTeacherCount: Number(pick(row, 'SharedTeacherCount', 'sharedTeacherCount') || 0),
      isOwner: Boolean(pick(row, 'IsOwner', 'isOwner')),
      canEdit: Boolean(pick(row, 'CanEdit', 'canEdit')),
      canOpenEditor: Boolean(pick(row, 'CanOpenEditor', 'canOpenEditor')),
      canDuplicate: Boolean(pick(row, 'CanDuplicate', 'canDuplicate')),
      hasLearningResults: Boolean(pick(row, 'HasLearningResults', 'hasLearningResults')),
      answerCount: Number(pick(row, 'AnswerCount', 'answerCount') || 0),
      canShare: Boolean(pick(row, 'CanShare', 'canShare')),
      canDelete: Boolean(pick(row, 'CanDelete', 'canDelete'))
    }))
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}
function clearFilters() {
  search.value = ''
  accessFilter.value = sourceFilter.value = usageFilter.value = statusFilter.value = 'ALL'
}
function thumbnailFor(item, index) {
  if (item.sourceType === 'YOUTUBE') return item.posterUrl || youtubeThumbnailUrl(item.videoUrl)
  const projectPoster =
    item.posterUrl &&
    (!/^https?:\/\//i.test(item.posterUrl) || /^https?:\/\/localhost(?::\d+)?\//i.test(item.posterUrl))
  return projectPoster ? resolveApiAssetUrl(item.posterUrl) : fallbackThumbnails[index % fallbackThumbnails.length]
}
function accessIcon(type) {
  return type === 'OWNER'
    ? 'bi-lock'
    : type === 'SCHOOL'
      ? 'bi-building'
      : type === 'SHARED'
        ? 'bi-person-check'
        : 'bi-shield-check'
}
function accessLabel(item) {
  if (item.accessType === 'OWNER') {
    if (item.shareScope === 'SCHOOL') return 'Tôi · Toàn trường'
    if (item.shareScope === 'SELECTED') return `Tôi · ${item.sharedTeacherCount} giáo viên`
    return 'Chỉ mình tôi'
  }
  if (item.accessType === 'SCHOOL') return 'Toàn trường'
  if (item.accessType === 'SHARED') return 'Chia sẻ cho tôi'
  return 'Quản trị viên'
}
function openUpload() {
  Object.assign(form, blank())
  youtubeInput.value = ''
  uploadProgress.value = 0
  uploadModal.value = true
}
function openEdit(item) {
  Object.assign(form, blank(), {
    id: item.id,
    title: item.title,
    sourceType: item.sourceType,
    videoUrl: item.videoUrl,
    posterUrl: item.posterUrl,
    durationSeconds: item.durationSeconds,
    originalFileName: item.originalFileName,
    fileSize: item.fileSize,
    mimeType: item.mimeType,
    status: item.status,
    usageCount: item.usageCount
  })
  youtubeInput.value = item.sourceType === 'YOUTUBE' ? item.videoUrl : ''
  uploadProgress.value = 0
  uploadModal.value = true
}
async function upload(event) {
  const file = event.target.files?.[0]
  event.target.value = ''
  if (!file) return
  uploading.value = true
  try {
    const body = new FormData()
    body.append('file', file)
    const result = await axiosClient.post('/videos/upload', body, {
      timeout: 0,
      onUploadProgress: (e) => (uploadProgress.value = e.total ? Math.round((e.loaded / e.total) * 100) : 0)
    })
    form.videoUrl = pick(result, 'videoUrl', 'VideoUrl')
    form.originalFileName = pick(result, 'originalFileName', 'OriginalFileName') || file.name
    form.fileSize = Number(pick(result, 'fileSize', 'FileSize') || file.size)
    form.mimeType = pick(result, 'mimeType', 'MimeType') || file.type
    form.title = file.name.replace(/\.[^.]+$/, '')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    uploading.value = false
  }
}
function changeSourceType(sourceType) {
  if (form.sourceType === sourceType) return
  form.sourceType = sourceType
  form.videoUrl = ''
  form.posterUrl = ''
  form.originalFileName = ''
  form.fileSize = 0
  form.mimeType = ''
  youtubeInput.value = ''
}
function applyYouTubeUrl() {
  const canonicalUrl = canonicalYouTubeUrl(youtubeInput.value)
  form.videoUrl = canonicalUrl
  form.posterUrl = youtubeThumbnailUrl(canonicalUrl)
  form.originalFileName = ''
  form.fileSize = 0
  form.mimeType = ''
}
function onYouTubeReady({ duration }) {
  if (duration > 0) form.durationSeconds = Math.max(1, Math.round(duration))
}
function readDuration() {
  if (metadataVideo.value?.duration && Number.isFinite(metadataVideo.value.duration))
    form.durationSeconds = Math.max(1, Math.round(metadataVideo.value.duration))
}
async function save() {
  if (form.sourceType === 'YOUTUBE') applyYouTubeUrl()
  if (!sourceIsValid.value) {
    show('Vui lòng chọn file video hoặc nhập liên kết YouTube hợp lệ.', 'danger')
    return
  }
  saving.value = true
  try {
    const payload = { ...form, durationSeconds: Math.max(1, Math.round(form.durationSeconds)) }
    if (form.id) await axiosClient.put(`/video-library/${form.id}`, payload)
    else await axiosClient.post('/video-library', payload)
    const edited = Boolean(form.id)
    uploadModal.value = false
    await load()
    show(
      edited
        ? `Đã cập nhật video và đồng bộ ${form.usageCount} bài học đang sử dụng.`
        : 'Đã thêm video riêng tư vào thư viện. Chỉ bạn nhìn thấy cho đến khi chia sẻ.'
    )
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
async function duplicateVideo(item) {
  const confirmed = await confirmDialog({
    title: 'Nhân bản video',
    message: `Tạo một bản độc lập từ “${item.title}”, bao gồm toàn bộ câu hỏi tương tác?`,
    confirmText: 'Nhân bản',
    tone: 'primary',
    icon: 'bi-copy'
  })
  if (!confirmed) return
  duplicatingId.value = item.id
  try {
    const result = await axiosClient.post(`/video-library/${item.id}/duplicate`, {
      title: `${item.title} - Bản sao`
    })
    const videoId = Number(pick(result, 'id', 'Id'))
    show('Đã nhân bản video và toàn bộ câu hỏi tương tác.')
    if (videoId) await router.push(`/cms/videos/${videoId}/editor`)
    else await load()
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    duplicatingId.value = 0
  }
}
async function openShare(item) {
  shareModal.value = true
  sharingLoading.value = true
  teacherSearch.value = ''
  Object.assign(shareForm, { assetId: item.id, title: item.title, shareScope: item.shareScope, teacherIds: [] })
  try {
    const data = await axiosClient.get(`/video-library/${item.id}/sharing`, { params: { _fresh: Date.now() } }),
      asset = pick(data, 'Asset', 'asset') || {}
    shareForm.shareScope = pick(asset, 'ShareScope', 'shareScope') || 'PRIVATE'
    shareTeachers.value = (pick(data, 'Teachers', 'teachers') || []).map((row) => ({
      id: Number(pick(row, 'Id', 'id')),
      fullName: pick(row, 'FullName', 'fullName') || '',
      email: pick(row, 'Email', 'email') || '',
      teacherCode: pick(row, 'TeacherCode', 'teacherCode') || '',
      isSelected: Boolean(pick(row, 'IsSelected', 'isSelected'))
    }))
    shareForm.teacherIds = shareTeachers.value.filter((t) => t.isSelected).map((t) => t.id)
  } catch (error) {
    closeShare()
    show(error.message, 'danger')
  } finally {
    sharingLoading.value = false
  }
}
function closeShare() {
  shareModal.value = false
  teacherSearch.value = ''
}
async function saveSharing() {
  sharingSaving.value = true
  try {
    await axiosClient.put(`/video-library/${shareForm.assetId}/sharing`, {
      shareScope: shareForm.shareScope,
      teacherIds: shareForm.shareScope === 'SELECTED' ? shareForm.teacherIds : []
    })
    closeShare()
    await load()
    show(
      shareForm.shareScope === 'PRIVATE'
        ? 'Đã chuyển video về chế độ chỉ mình tôi.'
        : shareForm.shareScope === 'SCHOOL'
          ? 'Đã chia sẻ video cho toàn bộ giáo viên trong trường.'
          : `Đã chia sẻ video cho ${shareForm.teacherIds.length} giáo viên.`
    )
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    sharingSaving.value = false
  }
}
async function remove(item) {
  if (!item.canDelete) return
  const confirmed = await confirmDialog({
    title: 'Xóa video',
    message: `Bạn có chắc muốn xóa “${item.title}” khỏi thư viện video?`,
    confirmText: 'Xóa video',
    tone: 'danger',
    icon: 'bi-trash3'
  })
  if (!confirmed) return
  try {
    await axiosClient.delete(`/video-library/${item.id}`)
    await load()
    show('Đã xóa video chưa sử dụng khỏi thư viện.')
  } catch (error) {
    show(error.message, 'danger')
  }
}
function initials(name) {
  return String(name || 'GV')
    .split(/\s+/)
    .filter(Boolean)
    .slice(-2)
    .map((x) => x[0])
    .join('')
    .toUpperCase()
}
function formatDate(value) {
  return value ? new Intl.DateTimeFormat('vi-VN').format(new Date(value)) : '—'
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
}
</script>

<style scoped src="../../assets/css/pages/cms/video-library.css"></style>
