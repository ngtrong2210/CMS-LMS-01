<template>
  <section>
    <header class="mb-5">
      <div class="section-title text-left">
        <div class="section-title__tagline-box">
          <span class="section-title__tagline">MÔN HỌC THEO LỚP</span>
        </div>
        <h1 class="section-title__title">Môn học của tôi</h1>
        <p class="mt-2">Theo dõi và tiếp tục các môn học lớp đã được phân.</p>
      </div>
    </header>

    <div class="row">
      <aside class="col-xl-4 col-lg-5">
        <div class="course-grid__sidebar">
          <div class="course-grid__search course-grid__single">
            <h3 class="mb-3">Tìm môn học</h3>
            <p class="course-grid__search-text">Tìm nhanh theo tên môn học hoặc giảng viên.</p>
            <form @submit.prevent>
              <input v-model="search" type="search" placeholder="Nhập từ khóa..." />
              <button type="submit">Tìm <i class="bi bi-search"></i></button>
            </form>
          </div>
          <div class="course-grid__price-filter course-grid__single">
            <h3 class="mb-3">Trạng thái học tập</h3>
            <div class="course-grid__price-filter-free-and-paid-course">
              <label class="custom-radio">
                <select v-model="status" class="form-select">
                  <option value="">Tất cả trạng thái</option>
                  <option value="ENROLLED">Chưa bắt đầu</option>
                  <option value="IN_PROGRESS">Đang học</option>
                  <option value="COMPLETED">Hoàn thành</option>
                </select>
              </label>
            </div>
          </div>
        </div>
      </aside>

      <div class="col-xl-8 col-lg-7">
        <div class="course-list__right">
          <div class="course-list__right-top">
            <p class="course-list__right-top-text">Hiển thị {{ filtered.length }} môn học</p>
            <div class="course-list__right-top-btn">
              <span><i class="bi bi-view-list"></i></span>
            </div>
          </div>

          <div v-if="loading" class="text-center py-5"><span class="spinner-border"></span></div>
          <div v-else-if="error" class="alert alert-danger">
            {{ error }}
            <button class="btn btn-sm btn-action-refresh ms-2" @click="loadCourses">
              <i class="bi bi-arrow-clockwise"></i> Thử lại
            </button>
          </div>
          <div v-else-if="!filtered.length" class="text-center py-5">
            <i class="bi bi-journal-x fs-1"></i>
            <p class="mt-2 mb-0">Không có môn học phù hợp.</p>
          </div>

          <template v-else>
            <article v-for="(course, index) in filtered" :key="course.id" class="course-list__single">
              <div class="course-list__img-box">
                <div class="course-list__img">
                  <img :src="courseImages[index % courseImages.length]" :alt="course.title" />
                </div>
              </div>
              <div class="course-list__content">
                <div class="course-list__doller-and-heart">
                  <div class="course-list__doller">
                    <p>{{ course.progress }}% hoàn thành</p>
                  </div>
                  <div class="course-list__heart">
                    <RouterLink :to="courseLessonLink(course)"><i class="bi bi-bookmark"></i></RouterLink>
                  </div>
                </div>
                <h2 class="course-list__title">
                  <RouterLink :to="courseLessonLink(course)">{{ course.title }}</RouterLink>
                </h2>
                <div class="course-list__ratting-box">
                  <div class="course-list__ratting">
                    <span v-for="star in 5" :key="star"><i class="bi bi-star-fill"></i></span>
                  </div>
                  <p class="course-list__ratting-text">{{ course.category }}</p>
                </div>
                <ul class="course-list__meta list-unstyled">
                  <li>
                    <p>
                      <span><i class="bi bi-bar-chart"></i></span
                      >{{ course.enrollmentStatus === 'COMPLETED' ? 'Hoàn thành' : 'Đang học' }}
                    </p>
                  </li>
                  <li>
                    <p>
                      <span><i class="bi bi-book"></i></span>{{ course.lessons }} bài học
                    </p>
                  </li>
                  <li>
                    <p>
                      <span><i class="bi bi-clock"></i></span>Học linh hoạt
                    </p>
                  </li>
                </ul>
                <div class="course-list__btn-and-client-info">
                  <div class="course-list__btn-box">
                    <RouterLink :to="courseLessonLink(course)" class="thm-btn"
                      >Mở môn học <i class="bi bi-arrow-right"></i
                    ></RouterLink>
                  </div>
                  <div class="course-list__client-box">
                    <div class="course-list__client-img">
                      <img :src="teacherImages[index % teacherImages.length]" :alt="course.teacher" />
                    </div>
                    <div class="course-list__client-content">
                      <h4>{{ course.teacher }}</h4>
                      <p>Giảng viên</p>
                    </div>
                  </div>
                </div>
              </div>
            </article>
          </template>
        </div>
      </div>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, ref } from 'vue'
import axiosClient from '../../api/axiosClient'
import { useListViewState } from '../../composables/useListViewState'
import courseList1 from '../../assets/eduvers/images/courses/course-list-img-1.jpg'
import courseList2 from '../../assets/eduvers/images/courses/course-list-img-2.jpg'
import courseList3 from '../../assets/eduvers/images/courses/course-list-img-3.jpg'
import courseList4 from '../../assets/eduvers/images/courses/course-list-img-4.jpg'
import courseList5 from '../../assets/eduvers/images/courses/course-list-img-5.jpg'
import teacher1 from '../../assets/eduvers/images/courses/course-list-client-img-1.jpg'
import teacher2 from '../../assets/eduvers/images/courses/course-list-client-img-2.jpg'
import teacher3 from '../../assets/eduvers/images/courses/course-list-client-img-3.jpg'
import teacher4 from '../../assets/eduvers/images/courses/course-list-client-img-4.jpg'
import teacher5 from '../../assets/eduvers/images/courses/course-list-client-img-5.jpg'
const courseImages = [courseList1, courseList2, courseList3, courseList4, courseList5],
  teacherImages = [teacher1, teacher2, teacher3, teacher4, teacher5]
const search = ref(''),
  status = ref(''),
  courses = ref([]),
  loading = ref(true),
  error = ref(''),
  pick = (source, ...names) =>
    names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
useListViewState('lms-courses', { search, status })
const colors = ['var(--eduvers-base)', 'var(--eduvers-black)', '#465f55', '#8a7000']
const filtered = computed(() =>
  courses.value.filter(
    (c) =>
      (!status.value || c.enrollmentStatus === status.value) &&
      `${c.title} ${c.teacher}`.toLowerCase().includes(search.value.toLowerCase())
  )
)
onMounted(loadCourses)
async function loadCourses() {
  loading.value = true
  error.value = ''
  try {
    const data = await axiosClient.get('/lms/courses', { params: { _fresh: Date.now() } })
    courses.value = (Array.isArray(data) ? data : []).map((row, index) => ({
      id: Number(pick(row, 'Id', 'id')),
      code: pick(row, 'Code', 'code') || '',
      title: pick(row, 'Title', 'title') || '',
      teacher: pick(row, 'TeacherName', 'teacherName') || '',
      category: pick(row, 'CategoryName', 'categoryName') || 'Môn học lớp',
      lessons: Number(pick(row, 'LessonCount', 'lessonCount') || 0),
      progress: Number(pick(row, 'ProgressPercent', 'progressPercent') || 0),
      continueLessonId: Number(pick(row, 'ContinueLessonId', 'continueLessonId') || 0),
      enrollmentStatus: pick(row, 'EnrollmentStatus', 'enrollmentStatus') || 'ENROLLED',
      color: colors[index % colors.length]
    }))
  } catch (e) {
    error.value = e.message
  } finally {
    loading.value = false
  }
}
function courseLessonLink(course) {
  return course?.continueLessonId
    ? `/lms/courses/${course.id}/lessons/${course.continueLessonId}`
    : `/lms/courses/${course.id}`
}
</script>
