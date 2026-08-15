<template>
  <section>
    <RouterLink to="/lms/courses" class="small"><i class="bi bi-arrow-left me-1"></i>Khóa học của tôi</RouterLink>
    <div v-if="loading" class="text-center py-5"><span class="spinner-border"></span></div>
    <div v-else-if="error" class="alert alert-danger my-3">
      {{ error }}
      <button class="btn btn-action-refresh btn-sm ms-2" @click="loadCourse">
        <i class="bi bi-arrow-clockwise"></i> Thử lại
      </button>
    </div>

    <template v-else>
      <div class="row mt-4">
        <div class="col-xl-8 col-lg-7">
          <div class="course-details__left">
            <div class="course-details__img"><img :src="courseDetailsImage" :alt="course.title" /></div>
            <div class="course-details__content">
              <div class="course-details__tag-box">
                <div class="course-details__tag-shape"></div>
                <span class="course-details__tag">{{ course.category }}</span>
              </div>
              <h1 class="course-details__title">{{ course.title }}</h1>
              <div class="course-details__client-and-ratting-box">
                <div class="course-details__client-box">
                  <div class="course-details__client-img"><img :src="courseTeacherImage" :alt="course.teacher" /></div>
                  <div class="course-details__client-content">
                    <p>Giảng viên phụ trách</p>
                    <h4>{{ course.teacher }}</h4>
                  </div>
                </div>
                <div class="course-details__ratting-box-1">
                  <ul class="course-details__ratting-list-1 list-unstyled">
                    <li>
                      <p>Nội dung</p>
                      <h4>{{ lessonCount }} bài học</h4>
                    </li>
                    <li>
                      <p>Thời lượng</p>
                      <h4>{{ formatDuration(totalDuration) }}</h4>
                    </li>
                    <li>
                      <p>Đánh giá khóa học</p>
                      <ul class="course-details__ratting list-unstyled">
                        <li v-for="star in 5" :key="star">
                          <span><i class="bi bi-star-fill"></i></span>
                        </li>
                      </ul>
                    </li>
                  </ul>
                </div>
              </div>

              <div class="course-details__main-tab-box">
                <div class="course-details__curriculam">
                  <h2 class="course-details__curriculam-title">Nội dung khóa học</h2>
                  <p class="course-details__curriculam-text">{{ course.description }}</p>
                  <div v-if="chapters.length" class="accordion accordion-flush" id="courseContent">
                    <div v-for="(chapter, index) in chapters" :key="chapter.id" class="accordion-item">
                      <h3 class="accordion-header">
                        <button
                          class="accordion-button"
                          :class="{ collapsed: index !== 0 }"
                          data-bs-toggle="collapse"
                          :data-bs-target="`#chapter${chapter.id}`"
                        >
                          <span class="me-3">{{ String(index + 1).padStart(2, '0') }}</span>
                          <span
                            ><strong>{{ chapter.title }}</strong
                            ><small class="d-block">{{ chapter.lessons.length }} bài học</small></span
                          >
                        </button>
                      </h3>
                      <div
                        :id="`chapter${chapter.id}`"
                        class="accordion-collapse collapse"
                        :class="{ show: index === 0 }"
                        data-bs-parent="#courseContent"
                      >
                        <div class="accordion-body">
                          <ul class="accrodion-content__points list-unstyled">
                            <li v-for="lesson in chapter.lessons" :key="lesson.id">
                              <RouterLink
                                :to="`/lms/courses/${course.id}/lessons/${lesson.id}`"
                                class="accrodion-content__points-text"
                              >
                                <span
                                  ><i
                                    :class="['bi', lesson.completed ? 'bi-check-circle-fill' : 'bi-play-circle']"
                                  ></i></span
                                >{{ lesson.title }}
                              </RouterLink>
                              <div class="accrodion-content__points-btn">
                                <RouterLink :to="`/lms/courses/${course.id}/lessons/${lesson.id}`">{{
                                  formatDuration(lesson.duration)
                                }}</RouterLink>
                              </div>
                            </li>
                          </ul>
                        </div>
                      </div>
                    </div>
                  </div>
                  <p v-else>Khóa học chưa có nội dung.</p>
                </div>
              </div>
            </div>
          </div>
        </div>

        <aside class="col-xl-4 col-lg-5">
          <div class="course-details__right">
            <div class="course-details__info-box">
              <div class="course-details__video-link">
                <div
                  class="course-details__video-link-bg"
                  :style="{ backgroundImage: `url(${courseDetailsImage})` }"
                ></div>
                <RouterLink
                  v-if="continueLessonId"
                  :to="`/lms/courses/${course.id}/lessons/${continueLessonId}`"
                  class="course-details__video-icon"
                  ><i class="bi bi-play-fill"></i><span class="ripple"></span
                ></RouterLink>
              </div>
              <div class="course-details__doller-and-btn-box">
                <div class="course-details__doller">{{ course.progress }}%</div>
                <div class="course-details__doller-btn-box">
                  <RouterLink
                    v-if="continueLessonId"
                    :to="`/lms/courses/${course.id}/lessons/${continueLessonId}`"
                    class="thm-btn"
                    >{{ completedCount ? 'Tiếp tục học' : 'Bắt đầu học' }} <i class="bi bi-arrow-right"></i
                  ></RouterLink>
                </div>
              </div>
              <div class="progress mb-4">
                <div class="progress-bar" :style="{ width: course.progress + '%' }"></div>
              </div>
              <div class="course-details__info-list">
                <h3 class="course-details__info-list-title">Thông tin khóa học</h3>
                <ul class="course-details__info-list-1 list-unstyled">
                  <li>
                    <p><i class="bi bi-journal-text"></i>Bài học</p>
                    <span>{{ completedCount }}/{{ lessonCount }}</span>
                  </li>
                  <li>
                    <p><i class="bi bi-clock"></i>Thời lượng</p>
                    <span>{{ formatDuration(totalDuration) }}</span>
                  </li>
                  <li>
                    <p><i class="bi bi-bar-chart"></i>Tiến độ</p>
                    <span>{{ course.progress }}%</span>
                  </li>
                  <li>
                    <p><i class="bi bi-award"></i>Điểm</p>
                    <span>{{ course.finalScore ?? '—' }}</span>
                  </li>
                </ul>
              </div>
            </div>
          </div>
        </aside>
      </div>
    </template>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import { useRoute } from 'vue-router'
import axiosClient from '../../api/axiosClient'
import courseDetailsImage from '../../assets/eduvers/images/courses/course-details-img-1.jpg'
import courseTeacherImage from '../../assets/eduvers/images/courses/course-details-client-img-1.jpg'
const route = useRoute(),
  loading = ref(true),
  error = ref(''),
  chapters = ref([]),
  course = reactive({
    id: 0,
    code: '',
    title: '',
    description: '',
    teacher: '',
    category: 'Khóa học',
    progress: 0,
    finalScore: null
  }),
  pick = (s, ...n) => n.map((x) => s?.[x]).find((v) => v !== undefined && v !== null)
const lessonCount = computed(() => chapters.value.reduce((n, c) => n + c.lessons.length, 0)),
  completedCount = computed(() => chapters.value.reduce((n, c) => n + c.lessons.filter((x) => x.completed).length, 0)),
  totalDuration = computed(() =>
    chapters.value.reduce((n, c) => n + c.lessons.reduce((sum, l) => sum + l.duration, 0), 0)
  ),
  allLessons = computed(() => chapters.value.flatMap((c) => c.lessons)),
  continueLessonId = computed(() => allLessons.value.find((x) => !x.completed)?.id || allLessons.value[0]?.id || 0)
onMounted(loadCourse)
async function loadCourse() {
  loading.value = true
  error.value = ''
  try {
    const data = await axiosClient.get(`/lms/courses/${Number(route.params.courseId)}`, {
        params: { _fresh: Date.now() }
      }),
      c = pick(data, 'course', 'Course') || {},
      rows = pick(data, 'lessons', 'Lessons') || []
    Object.assign(course, {
      id: Number(pick(c, 'Id', 'id')),
      code: pick(c, 'Code', 'code') || '',
      title: pick(c, 'Title', 'title') || '',
      description: pick(c, 'Description', 'description') || pick(c, 'ShortDescription', 'shortDescription') || '',
      teacher: pick(c, 'TeacherName', 'teacherName') || '',
      category: pick(c, 'CategoryName', 'categoryName') || 'Khóa học',
      progress: Number(pick(c, 'ProgressPercent', 'progressPercent') || 0),
      finalScore: pick(c, 'FinalScore', 'finalScore')
    })
    chapters.value = (pick(data, 'chapters', 'Chapters') || []).map((ch) => {
      const id = Number(pick(ch, 'Id', 'id'))
      return {
        id,
        title: pick(ch, 'Title', 'title') || '',
        lessons: rows
          .filter((l) => Number(pick(l, 'ChapterId', 'chapterId')) === id)
          .map((l) => ({
            id: Number(pick(l, 'Id', 'id')),
            title: pick(l, 'Title', 'title') || '',
            duration: Number(pick(l, 'DurationSeconds', 'durationSeconds') || 0),
            completed: Boolean(pick(l, 'Completed', 'completed'))
          }))
      }
    })
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
function formatDuration(seconds) {
  const minutes = Math.round(Number(seconds || 0) / 60)
  return minutes >= 60 ? `${Math.floor(minutes / 60)} giờ ${minutes % 60} phút` : `${minutes} phút`
}
</script>
