<template>
  <section class="academic-page">
    <header class="academic-heading">
      <div>
        <span class="eyebrow">CƠ CẤU ĐÀO TẠO</span>
        <h1 class="page-title">Khóa · Khoa · Lớp · Môn học</h1>
        <p class="page-subtitle">Quản lý môn học lớp theo năm học và liên kết trực tiếp với nội dung LMS.</p>
      </div>
      <CmsPageActions v-if="isAdmin">
        <button class="btn btn-action-create" @click="openCreate('CLASS_SUBJECT')">
          <i class="bi bi-calendar2-plus"></i> Mở môn cho lớp
        </button>
      </CmsPageActions>
    </header>

    <div v-if="message" :class="['alert', messageType === 'danger' ? 'alert-danger' : 'alert-success']">
      {{ message }}
    </div>

    <div class="app-card academic-toolbar">
      <div class="toolbar-title">
        <i class="bi bi-funnel"></i>
        <div>
          <strong>{{ filterTitle }}</strong
          ><small>{{ filterSubtitle }}</small>
        </div>
      </div>
      <label class="keyword-filter">
        <span>Tìm nhanh</span>
        <div class="filter-search">
          <i class="bi bi-search"></i
          ><input v-model.trim="filters.keyword" class="form-control" :placeholder="filterPlaceholder" />
        </div>
      </label>
      <label v-if="['offerings', 'timetable'].includes(activeTab)">
        <span>Năm học</span>
        <select v-model="filters.yearId" class="form-select">
          <option value="">Tất cả năm học</option>
          <option v-for="year in years" :key="year.yearId" :value="String(year.yearId)">{{ year.yearName }}</option>
        </select>
      </label>
      <label v-if="['offerings', 'timetable'].includes(activeTab)">
        <span>Học kỳ</span>
        <select v-model="filters.semester" class="form-select">
          <option value="">Tất cả học kỳ</option>
          <option value="1">Học kỳ 1</option>
          <option value="2">Học kỳ 2</option>
          <option value="3">Học kỳ hè</option>
        </select>
      </label>
      <label v-if="['offerings', 'timetable'].includes(activeTab)">
        <span>Lớp</span>
        <select v-model="filters.classId" class="form-select">
          <option value="">Tất cả lớp</option>
          <option v-for="item in classes" :key="item.classId" :value="item.classId">{{ item.className }}</option>
        </select>
      </label>
      <label v-if="['classes', 'subjects'].includes(activeTab)">
        <span>Khoa</span>
        <select v-model="filters.scienceName" class="form-select">
          <option value="">Tất cả khoa</option>
          <option v-for="item in scienceFilterOptions" :key="item" :value="item">{{ item }}</option>
        </select>
      </label>
      <label v-if="activeTab === 'students'">
        <span>Lớp</span>
        <select v-model="filters.studentClassId" class="form-select">
          <option value="">Tất cả lớp</option>
          <option v-for="item in classes" :key="item.classId" :value="item.classId">{{ item.className }}</option>
        </select>
      </label>
      <div v-if="supportsViewMode" class="view-mode-field">
        <span>Hiển thị</span>
        <div class="view-mode-switch" role="group" :aria-label="`Chế độ hiển thị ${activeTabLabel}`">
          <button type="button" :class="{ active: viewMode === 'list' }" title="Danh sách" @click="setViewMode('list')">
            <i class="bi bi-list-ul"></i><span>Danh sách</span>
          </button>
          <button
            type="button"
            :class="{ active: viewMode === 'cards' }"
            title="Dạng thẻ"
            @click="setViewMode('cards')"
          >
            <i class="bi bi-grid"></i><span>Dạng thẻ</span>
          </button>
        </div>
      </div>
    </div>

    <nav class="academic-tabs" aria-label="Nhóm dữ liệu đào tạo">
      <button
        v-for="tab in tabs"
        :key="tab.key"
        :class="['academic-tab', `academic-tab-${tab.key}`, { active: activeTab === tab.key }]"
        @click="activeTab = tab.key"
      >
        <i :class="['bi', tab.icon]"></i>{{ tab.label }}<span>{{ tab.count }}</span>
      </button>
    </nav>

    <div v-if="loading" class="app-card loading-card"><span class="spinner-border text-brand"></span></div>

    <section v-else-if="activeTab === 'offerings'" class="offering-results">
      <div v-if="viewMode === 'list'" class="app-card table-card">
        <div class="table-card-heading">
          <div>
            <strong>Môn học lớp đang mở</strong><small>Mỗi dòng là một môn của một lớp trong một năm và học kỳ.</small>
          </div>
        </div>
        <div class="table-responsive">
          <table class="table align-middle academic-table">
            <thead>
              <tr>
                <th>STT</th>
                <th>Năm / Học kỳ</th>
                <th>Lớp</th>
                <th>Môn học</th>
                <th>Giảng viên</th>
                <th>Nội dung LMS</th>
                <th>Quy mô</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in filteredOfferings" :key="item.classSubjectId">
                <td>{{ index + 1 }}</td>
                <td>
                  <strong>{{ item.yearName }}</strong
                  ><small>Học kỳ {{ item.semester }}</small>
                </td>
                <td>
                  <strong>{{ item.className }}</strong
                  ><small>{{ item.classId }}</small>
                </td>
                <td>
                  <strong>{{ item.subjectName }}</strong
                  ><small>{{ item.subjectId }} · {{ item.creditCount }} tín chỉ</small>
                </td>
                <td>{{ item.teacherName || 'Chưa phân công' }}</td>
                <td>
                  <RouterLink
                    v-if="item.onlineCourseId"
                    class="course-link"
                    :to="`/cms/courses/${item.onlineCourseId}/content`"
                  >
                    <i class="bi bi-box-arrow-up-right"></i
                    ><span
                      ><strong>{{ item.onlineCourseTitle }}</strong
                      ><small>{{ item.chapterCount }} chương · {{ item.lessonCount }} bài</small></span
                    >
                  </RouterLink>
                  <span v-else class="badge badge-soft-warning">Chưa tạo nội dung</span>
                </td>
                <td>
                  <strong>{{ item.studentCount }} học viên</strong
                  ><small>{{ item.theoryQuantity }} LT · {{ item.practiceQuantity }} TH</small>
                </td>
              </tr>
              <tr v-if="!filteredOfferings.length">
                <td colspan="7" class="empty-cell">Không có môn học lớp phù hợp bộ lọc.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div v-else-if="filteredOfferings.length" class="offering-grid">
        <article v-for="item in filteredOfferings" :key="item.classSubjectId" class="app-card offering-card">
          <header>
            <span class="offering-icon"><i class="bi bi-journal-bookmark-fill"></i></span>
            <span class="badge badge-soft-primary">{{ item.yearName }} · HK{{ item.semester }}</span>
          </header>
          <div class="offering-card-title">
            <h3>{{ item.subjectName }}</h3>
            <small>{{ item.subjectId }} · {{ item.creditCount }} tín chỉ</small>
          </div>
          <dl>
            <div>
              <dt>Lớp</dt>
              <dd>{{ item.className }}</dd>
            </div>
            <div>
              <dt>Giảng viên</dt>
              <dd>{{ item.teacherName || 'Chưa phân công' }}</dd>
            </div>
            <div>
              <dt>Học viên</dt>
              <dd>{{ item.studentCount }} học viên</dd>
            </div>
            <div>
              <dt>Khối lượng</dt>
              <dd>{{ item.theoryQuantity }} LT · {{ item.practiceQuantity }} TH</dd>
            </div>
          </dl>
          <footer>
            <RouterLink
              v-if="item.onlineCourseId"
              class="btn btn-action-view btn-sm"
              :to="`/cms/courses/${item.onlineCourseId}/content`"
            >
              <i class="bi bi-box-arrow-up-right"></i> Mở nội dung LMS
            </RouterLink>
            <span v-else class="badge badge-soft-warning">Chưa tạo nội dung LMS</span>
          </footer>
        </article>
      </div>
      <div v-else class="app-card empty-cell">Không có môn học lớp phù hợp bộ lọc.</div>
    </section>

    <div v-else-if="activeTab === 'timetable'" class="app-card table-card">
      <div class="table-card-heading timetable-heading">
        <div><strong>Thời khóa biểu</strong><small>Lịch học của từng môn học lớp trong năm học.</small></div>
        <button v-if="isAdmin" class="btn btn-action-create btn-sm" @click="openCreate('TIMETABLE')">
          <i class="bi bi-calendar2-plus"></i> Thêm lịch học
        </button>
      </div>
      <div class="table-responsive">
        <table class="table align-middle academic-table timetable-table">
          <thead>
            <tr>
              <th>STT</th>
              <th>Thứ</th>
              <th>Thời gian</th>
              <th>Lớp / Môn học</th>
              <th>Phòng</th>
              <th>Hiệu lực</th>
              <th v-if="isAdmin" class="action-cell">Thao tác</th>
            </tr>
          </thead>
          <tbody>
            <tr v-for="(item, index) in filteredTimetables" :key="item.timetableId">
              <td>{{ index + 1 }}</td>
              <td>
                <span class="day-badge">{{ dayLabel(item.dayOfWeek) }}</span>
              </td>
              <td>
                <strong>{{ timeText(item.startTime) }} – {{ timeText(item.endTime) }}</strong
                ><small>Tiết {{ item.startPeriod || '—' }} – {{ item.endPeriod || '—' }}</small>
              </td>
              <td>
                <strong>{{ item.subjectName }}</strong
                ><small>{{ item.className }} · {{ item.yearName }} · HK{{ item.semester }}</small>
              </td>
              <td>{{ item.roomName || 'Chưa xếp phòng' }}</td>
              <td>{{ dateText(item.effectiveFrom) }} – {{ dateText(item.effectiveTo) }}</td>
              <td v-if="isAdmin" class="action-cell">
                <button class="btn btn-action-view btn-sm" @click="openTimetable(item)">
                  <i class="bi bi-pencil-square"></i> Sửa lịch
                </button>
              </td>
            </tr>
            <tr v-if="!filteredTimetables.length">
              <td :colspan="isAdmin ? 7 : 6" class="empty-cell">Không có lịch học phù hợp bộ lọc.</td>
            </tr>
          </tbody>
        </table>
      </div>
    </div>

    <section v-else-if="activeTab === 'classes'" class="catalog-results">
      <div v-if="viewMode === 'cards'" class="catalog-grid">
        <article v-for="item in filteredClasses" :key="item.classId" class="app-card catalog-card">
          <header>
            <span class="catalog-icon blue"><i class="bi bi-people"></i></span><span class="status-dot"></span>
          </header>
          <strong>{{ item.className }}</strong
          ><small>{{ item.classId }} · {{ item.scienceName }}</small>
          <dl>
            <div>
              <dt>Khóa</dt>
              <dd>{{ item.courseName }}</dd>
            </div>
            <div>
              <dt>Sĩ số</dt>
              <dd>{{ item.studentCount }}/{{ item.classSize }}</dd>
            </div>
          </dl>
          <button v-if="isAdmin" class="btn btn-action-view btn-sm" @click="openAssign(item)">
            <i class="bi bi-person-check"></i> Phân học viên
          </button>
        </article>
        <button
          v-if="isAdmin && !filters.keyword && !filters.scienceName"
          class="app-card catalog-add"
          @click="openCreate('CLASS')"
        >
          <i class="bi bi-plus-circle"></i><span>Thêm lớp hành chính</span>
        </button>
      </div>
      <div v-else class="app-card table-card">
        <div class="table-responsive">
          <table class="table align-middle academic-table">
            <thead>
              <tr>
                <th>STT</th>
                <th>Lớp</th>
                <th>Khoa</th>
                <th>Khóa</th>
                <th>Sĩ số</th>
                <th v-if="isAdmin">Thao tác</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in filteredClasses" :key="item.classId">
                <td>{{ index + 1 }}</td>
                <td>
                  <strong>{{ item.className }}</strong
                  ><small>{{ item.classId }}</small>
                </td>
                <td>{{ item.scienceName }}</td>
                <td>{{ item.courseName }}</td>
                <td>{{ item.studentCount }}/{{ item.classSize }} học viên</td>
                <td v-if="isAdmin">
                  <button class="btn btn-action-view btn-sm" @click="openAssign(item)">
                    <i class="bi bi-person-check"></i> Phân học viên
                  </button>
                </td>
              </tr>
              <tr v-if="!filteredClasses.length">
                <td :colspan="isAdmin ? 6 : 5" class="empty-cell">Không có lớp phù hợp bộ lọc.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div v-if="viewMode === 'cards' && !filteredClasses.length" class="app-card empty-cell">
        Không có lớp phù hợp bộ lọc.
      </div>
    </section>

    <section v-else-if="activeTab === 'subjects'" class="catalog-results">
      <div v-if="viewMode === 'cards'" class="catalog-grid">
        <article v-for="item in filteredSubjects" :key="item.subjectId" class="app-card catalog-card">
          <header>
            <span class="catalog-icon green"><i class="bi bi-book"></i></span
            ><span class="credit-badge">{{ item.creditCount }} TC</span>
          </header>
          <strong>{{ item.subjectName }}</strong
          ><small>{{ item.subjectId }} · {{ item.scienceName }}</small>
          <dl>
            <div>
              <dt>Lý thuyết</dt>
              <dd>{{ item.theoryQuantity }} tiết</dd>
            </div>
            <div>
              <dt>Thực hành</dt>
              <dd>{{ item.practiceQuantity }} tiết</dd>
            </div>
          </dl>
        </article>
        <button
          v-if="isAdmin && !filters.keyword && !filters.scienceName"
          class="app-card catalog-add"
          @click="openCreate('SUBJECT')"
        >
          <i class="bi bi-plus-circle"></i><span>Thêm môn học</span>
        </button>
      </div>
      <div v-else class="app-card table-card">
        <div class="table-responsive">
          <table class="table align-middle academic-table">
            <thead>
              <tr>
                <th>STT</th>
                <th>Môn học</th>
                <th>Khoa</th>
                <th>Tín chỉ</th>
                <th>Lý thuyết</th>
                <th>Thực hành</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in filteredSubjects" :key="item.subjectId">
                <td>{{ index + 1 }}</td>
                <td>
                  <strong>{{ item.subjectName }}</strong
                  ><small>{{ item.subjectId }}</small>
                </td>
                <td>{{ item.scienceName }}</td>
                <td>{{ item.creditCount }} tín chỉ</td>
                <td>{{ item.theoryQuantity }} tiết</td>
                <td>{{ item.practiceQuantity }} tiết</td>
              </tr>
              <tr v-if="!filteredSubjects.length">
                <td colspan="6" class="empty-cell">Không có môn học phù hợp bộ lọc.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div v-if="viewMode === 'cards' && !filteredSubjects.length" class="app-card empty-cell">
        Không có môn học phù hợp bộ lọc.
      </div>
    </section>

    <section v-else-if="activeTab === 'students'" class="catalog-results">
      <div v-if="viewMode === 'cards'" class="student-grid">
        <article v-for="item in filteredStudents" :key="item.studentId" class="app-card student-card">
          <span class="catalog-icon blue"><i class="bi bi-person"></i></span>
          <div>
            <strong>{{ item.fullName }}</strong
            ><small>{{ item.studentId }} · {{ item.className || 'Chưa xếp lớp' }}</small
            ><span>{{ item.email || 'Chưa có email' }}</span>
          </div>
          <span class="badge badge-soft-success">Đang học</span>
        </article>
      </div>
      <div v-else class="app-card table-card">
        <div class="table-responsive">
          <table class="table align-middle academic-table">
            <thead>
              <tr>
                <th>STT</th>
                <th>Học viên</th>
                <th>Mã sinh viên</th>
                <th>Lớp</th>
                <th>Liên hệ</th>
                <th>Trạng thái</th>
              </tr>
            </thead>
            <tbody>
              <tr v-for="(item, index) in filteredStudents" :key="item.studentId">
                <td>{{ index + 1 }}</td>
                <td>
                  <strong>{{ item.fullName }}</strong>
                </td>
                <td>{{ item.studentId }}</td>
                <td>{{ item.className }}</td>
                <td>
                  <span>{{ item.email || '—' }}</span
                  ><small>{{ item.mobile || '' }}</small>
                </td>
                <td><span class="badge badge-soft-success">Đang học</span></td>
              </tr>
              <tr v-if="!filteredStudents.length">
                <td colspan="6" class="empty-cell">Không có học viên phù hợp bộ lọc.</td>
              </tr>
            </tbody>
          </table>
        </div>
      </div>
      <div v-if="viewMode === 'cards' && !filteredStudents.length" class="app-card empty-cell">
        Không có học viên phù hợp bộ lọc.
      </div>
    </section>

    <div v-else class="catalog-sections">
      <section class="app-card mini-catalog">
        <header>
          <div><strong>Năm học</strong><small>Chu kỳ tổ chức đào tạo</small></div>
          <button v-if="isAdmin" @click="openCreate('YEAR')"><i class="bi bi-plus"></i></button>
        </header>
        <div v-for="item in filteredYears" :key="item.yearId">
          <span><i class="bi bi-calendar3"></i>{{ item.yearName }}</span
          ><small>{{ dateText(item.startAt) }} – {{ dateText(item.finishAt) }}</small>
        </div>
      </section>
      <section class="app-card mini-catalog">
        <header>
          <div><strong>Khoa</strong><small>Đơn vị chuyên môn</small></div>
          <button v-if="isAdmin" @click="openCreate('SCIENCE')"><i class="bi bi-plus"></i></button>
        </header>
        <div v-for="item in filteredSciences" :key="item.scienceId">
          <span><i class="bi bi-building"></i>{{ item.scienceName }}</span
          ><small>{{ item.scienceId }}</small>
        </div>
      </section>
      <section class="app-card mini-catalog">
        <header>
          <div><strong>Khóa tuyển sinh</strong><small>K18, K19...</small></div>
          <button v-if="isAdmin" @click="openCreate('COHORT')"><i class="bi bi-plus"></i></button>
        </header>
        <div v-for="item in filteredCohorts" :key="item.courseId">
          <span><i class="bi bi-mortarboard"></i>{{ item.courseName }}</span
          ><small>{{ item.startYear }} – {{ item.finishYear }}</small>
        </div>
      </section>
    </div>

    <div v-if="formModal" class="modal-mask" @click.self="formModal = false">
      <form class="app-card academic-modal" @submit.prevent="saveCatalog">
        <div class="modal-heading">
          <div>
            <small>DANH MỤC ĐÀO TẠO</small>
            <h2>{{ formTitle }}</h2>
          </div>
          <button type="button" class="btn-close" @click="formModal = false"></button>
        </div>
        <div class="row g-3">
          <template v-if="!['CLASS_SUBJECT', 'TIMETABLE'].includes(form.entityType)">
            <div class="col-md-5">
              <label class="form-label">Mã</label><input v-model.trim="form.code" class="form-control" required />
            </div>
            <div class="col-md-7">
              <label class="form-label">Tên hiển thị</label
              ><input v-model.trim="form.name" class="form-control" required />
            </div>
          </template>
          <div v-if="['SUBJECT', 'CLASS'].includes(form.entityType)" class="col-md-6">
            <label class="form-label">Khoa</label
            ><select v-model="form.parentCode" class="form-select" required>
              <option value="">Chọn khoa</option>
              <option v-for="item in sciences" :key="item.scienceId" :value="item.scienceId">
                {{ item.scienceName }}
              </option>
            </select>
          </div>
          <div v-if="form.entityType === 'CLASS'" class="col-md-6">
            <label class="form-label">Khóa tuyển sinh</label
            ><select v-model="form.subjectId" class="form-select" required>
              <option value="">Chọn khóa</option>
              <option v-for="item in cohorts" :key="item.courseId" :value="item.courseId">{{ item.courseName }}</option>
            </select>
          </div>
          <div v-if="form.entityType === 'YEAR'" class="col-md-6">
            <label class="form-label">Bắt đầu</label><input v-model="form.startAt" class="form-control" type="date" />
          </div>
          <div v-if="form.entityType === 'YEAR'" class="col-md-6">
            <label class="form-label">Kết thúc</label><input v-model="form.finishAt" class="form-control" type="date" />
          </div>
          <div v-if="form.entityType === 'COHORT'" class="col-md-6">
            <label class="form-label">Năm bắt đầu</label
            ><input v-model.number="form.startYear" class="form-control" type="number" required />
          </div>
          <div v-if="form.entityType === 'COHORT'" class="col-md-6">
            <label class="form-label">Năm kết thúc</label
            ><input v-model.number="form.finishYear" class="form-control" type="number" required />
          </div>
          <template v-if="form.entityType === 'SUBJECT'"
            ><div class="col-md-4">
              <label class="form-label">Tín chỉ</label
              ><input v-model.number="form.creditCount" class="form-control" type="number" min="0" />
            </div>
            <div class="col-md-4">
              <label class="form-label">Tiết lý thuyết</label
              ><input v-model.number="form.theoryQuantity" class="form-control" type="number" min="0" />
            </div>
            <div class="col-md-4">
              <label class="form-label">Tiết thực hành</label
              ><input v-model.number="form.practiceQuantity" class="form-control" type="number" min="0" /></div
          ></template>
          <template v-if="form.entityType === 'CLASS_SUBJECT'"
            ><div class="col-md-6">
              <label class="form-label">Năm học</label
              ><select v-model.number="form.yearId" class="form-select" required>
                <option :value="null">Chọn năm</option>
                <option v-for="item in years" :key="item.yearId" :value="item.yearId">{{ item.yearName }}</option>
              </select>
            </div>
            <div class="col-md-6">
              <label class="form-label">Học kỳ</label
              ><select v-model.number="form.semester" class="form-select" required>
                <option :value="null">Chọn học kỳ</option>
                <option :value="1">Học kỳ 1</option>
                <option :value="2">Học kỳ 2</option>
                <option :value="3">Học kỳ hè</option>
              </select>
            </div>
            <div class="col-md-6">
              <label class="form-label">Lớp</label
              ><select v-model="form.classId" class="form-select" required>
                <option value="">Chọn lớp</option>
                <option v-for="item in classes" :key="item.classId" :value="item.classId">{{ item.className }}</option>
              </select>
            </div>
            <div class="col-md-6">
              <label class="form-label">Môn học</label
              ><select v-model="form.subjectId" class="form-select" required>
                <option value="">Chọn môn</option>
                <option v-for="item in subjects" :key="item.subjectId" :value="item.subjectId">
                  {{ item.subjectName }}
                </option>
              </select>
            </div>
            <div class="col-12">
              <label class="form-label">Giảng viên</label
              ><select v-model="form.teacherId" class="form-select">
                <option value="">Chưa phân công</option>
                <option v-for="item in teachers" :key="item.teacherId" :value="item.teacherId">
                  {{ item.teacherName }}
                </option>
              </select>
            </div></template
          >
          <template v-if="form.entityType === 'TIMETABLE'"
            ><div class="col-12">
              <label class="form-label">Môn học lớp</label
              ><select v-model.number="form.classSubjectId" class="form-select" required>
                <option :value="null">Chọn môn học lớp</option>
                <option v-for="item in offerings" :key="item.classSubjectId" :value="item.classSubjectId">
                  {{ item.className }} · {{ item.subjectName }} · {{ item.yearName }} HK{{ item.semester }}
                </option>
              </select>
            </div>
            <div class="col-md-4">
              <label class="form-label">Thứ</label
              ><select v-model.number="form.dayOfWeek" class="form-select" required>
                <option :value="null">Chọn thứ</option>
                <option v-for="day in weekDays" :key="day.value" :value="day.value">{{ day.label }}</option>
              </select>
            </div>
            <div class="col-md-4">
              <label class="form-label">Tiết bắt đầu</label
              ><input v-model.number="form.startPeriod" class="form-control" type="number" min="1" max="30" />
            </div>
            <div class="col-md-4">
              <label class="form-label">Tiết kết thúc</label
              ><input v-model.number="form.endPeriod" class="form-control" type="number" min="1" max="30" />
            </div>
            <div class="col-md-4">
              <label class="form-label">Giờ bắt đầu</label
              ><input v-model="form.startTime" class="form-control" type="time" />
            </div>
            <div class="col-md-4">
              <label class="form-label">Giờ kết thúc</label
              ><input v-model="form.endTime" class="form-control" type="time" />
            </div>
            <div class="col-md-4">
              <label class="form-label">Phòng học</label
              ><input v-model.trim="form.roomName" class="form-control" placeholder="Ví dụ: LAB.02" />
            </div>
            <div class="col-md-6">
              <label class="form-label">Hiệu lực từ ngày</label
              ><input v-model="form.effectiveFrom" class="form-control" type="date" />
            </div>
            <div class="col-md-6">
              <label class="form-label">Hiệu lực đến ngày</label
              ><input v-model="form.effectiveTo" class="form-control" type="date" /></div
          ></template>
        </div>
        <div class="modal-actions">
          <button type="button" class="btn btn-action-cancel" @click="formModal = false">
            <i class="bi bi-x-lg"></i> Hủy</button
          ><button class="btn btn-action-save" :disabled="saving">
            <span v-if="saving" class="spinner-border spinner-border-sm"></span
            ><i v-else class="bi bi-check-lg"></i> Lưu danh mục
          </button>
        </div>
      </form>
    </div>

    <div v-if="assignModal" class="modal-mask" @click.self="assignModal = false">
      <form class="app-card academic-modal assign-modal" @submit.prevent="assignStudents">
        <div class="modal-heading">
          <div>
            <small>PHÂN HỌC VIÊN</small>
            <h2>{{ assignTarget?.className }}</h2>
            <p>Chọn nhiều học viên; hệ thống tự ghi danh các môn LMS của lớp.</p>
          </div>
          <button type="button" class="btn-close" @click="assignModal = false"></button>
        </div>
        <label class="search-students"
          ><i class="bi bi-search"></i
          ><input v-model.trim="studentSearch" placeholder="Tìm theo tên hoặc mã sinh viên..."
        /></label>
        <div class="student-select-list">
          <label
            v-for="item in assignableStudents"
            :key="item.userId"
            :class="{ selected: selectedStudents.includes(item.userId) }"
            ><input v-model="selectedStudents" type="checkbox" :value="item.userId" /><span
              ><strong>{{ item.fullName }}</strong
              ><small>{{ item.studentId }} · {{ item.className }}</small></span
            ></label
          >
        </div>
        <div class="modal-actions">
          <span class="selection-count">Đã chọn {{ selectedStudents.length }} học viên</span
          ><button type="button" class="btn btn-action-cancel" @click="assignModal = false">Hủy</button
          ><button class="btn btn-action-save" :disabled="saving || !selectedStudents.length">
            <i class="bi bi-person-check"></i> Phân vào lớp
          </button>
        </div>
      </form>
    </div>
  </section>
</template>

<script setup>
import { computed, onMounted, reactive, ref } from 'vue'
import axiosClient from '../../api/axiosClient'
import CmsPageActions from '../../components/navigation/CmsPageActions.vue'
import { useAuthStore } from '../../stores/authStore'

const auth = useAuthStore()
const isAdmin = computed(() => auth.user?.role === 'ADMIN')
const loading = ref(true)
const saving = ref(false)
const message = ref('')
const messageType = ref('success')
const activeTab = ref('offerings')
const formModal = ref(false)
const assignModal = ref(false)
const assignTarget = ref(null)
const studentSearch = ref('')
const selectedStudents = ref([])
const years = ref([])
const sciences = ref([])
const cohorts = ref([])
const classes = ref([])
const subjects = ref([])
const teachers = ref([])
const students = ref([])
const offerings = ref([])
const timetables = ref([])
const filters = reactive({ keyword: '', yearId: '', semester: '', classId: '', scienceName: '', studentClassId: '' })
const viewModes = reactive({
  offerings:
    window.localStorage.getItem('cms-academic-view-offerings') ||
    window.localStorage.getItem('cms-academic-offering-view') ||
    'list',
  classes: window.localStorage.getItem('cms-academic-view-classes') || 'cards',
  subjects: window.localStorage.getItem('cms-academic-view-subjects') || 'cards',
  students: window.localStorage.getItem('cms-academic-view-students') || 'list'
})
const form = reactive(blankForm())
const pick = (source, ...names) =>
  names.map((name) => source?.[name]).find((value) => value !== undefined && value !== null)
const weekDays = [
  { value: 2, label: 'Thứ Hai' },
  { value: 3, label: 'Thứ Ba' },
  { value: 4, label: 'Thứ Tư' },
  { value: 5, label: 'Thứ Năm' },
  { value: 6, label: 'Thứ Sáu' },
  { value: 7, label: 'Thứ Bảy' },
  { value: 8, label: 'Chủ nhật' }
]
const tabs = computed(() => [
  { key: 'offerings', label: 'Môn học lớp', icon: 'bi-calendar2-week', count: offerings.value.length },
  { key: 'timetable', label: 'Thời khóa biểu', icon: 'bi-clock-history', count: timetables.value.length },
  { key: 'classes', label: 'Lớp', icon: 'bi-people', count: classes.value.length },
  { key: 'subjects', label: 'Môn học', icon: 'bi-book', count: subjects.value.length },
  { key: 'students', label: 'Học viên', icon: 'bi-person-badge', count: students.value.length },
  {
    key: 'catalog',
    label: 'Danh mục gốc',
    icon: 'bi-diagram-3',
    count: years.value.length + sciences.value.length + cohorts.value.length
  }
])
const activeTabLabel = computed(() => tabs.value.find((tab) => tab.key === activeTab.value)?.label || 'dữ liệu')
const filterTitle = computed(() => `Lọc ${activeTabLabel.value.toLowerCase()}`)
const filterSubtitle = computed(
  () =>
    ({
      offerings: 'Thu hẹp theo từ khóa, năm học, học kỳ và lớp hành chính',
      timetable: 'Tìm lịch theo môn, lớp, phòng, năm học và học kỳ',
      classes: 'Tìm theo mã lớp, tên lớp, khoa hoặc khóa tuyển sinh',
      subjects: 'Tìm theo mã môn, tên môn hoặc khoa phụ trách',
      students: 'Tìm theo tên, mã sinh viên, email hoặc lớp',
      catalog: 'Tìm trong năm học, khoa và khóa tuyển sinh'
    })[activeTab.value] || 'Tìm và thu hẹp dữ liệu hiển thị'
)
const filterPlaceholder = computed(
  () =>
    ({
      offerings: 'Tên môn, mã môn, lớp hoặc giảng viên...',
      timetable: 'Tên môn, lớp hoặc phòng học...',
      classes: 'Mã lớp, tên lớp hoặc khóa...',
      subjects: 'Mã môn hoặc tên môn học...',
      students: 'Tên, mã sinh viên hoặc email...',
      catalog: 'Tên hoặc mã danh mục...'
    })[activeTab.value] || 'Tìm kiếm...'
)
const supportsViewMode = computed(() => ['offerings', 'classes', 'subjects', 'students'].includes(activeTab.value))
const viewMode = computed(() => viewModes[activeTab.value] || 'list')
const normalizedKeyword = computed(() => filters.keyword.toLocaleLowerCase('vi-VN'))
const containsKeyword = (...values) =>
  !normalizedKeyword.value ||
  values.some((value) =>
    String(value || '')
      .toLocaleLowerCase('vi-VN')
      .includes(normalizedKeyword.value)
  )
const scienceFilterOptions = computed(() =>
  [...new Set([...classes.value, ...subjects.value].map((item) => item.scienceName).filter(Boolean))].sort(
    (left, right) => left.localeCompare(right, 'vi')
  )
)
const filteredOfferings = computed(() =>
  offerings.value.filter(
    (item) =>
      (!filters.yearId || String(item.yearId) === filters.yearId) &&
      (!filters.semester || String(item.semester) === filters.semester) &&
      (!filters.classId || item.classId === filters.classId) &&
      containsKeyword(
        item.subjectId,
        item.subjectName,
        item.classId,
        item.className,
        item.teacherName,
        item.onlineCourseTitle
      )
  )
)
const filteredTimetables = computed(() =>
  timetables.value.filter(
    (item) =>
      (!filters.yearId || String(item.yearId) === filters.yearId) &&
      (!filters.semester || String(item.semester) === filters.semester) &&
      (!filters.classId || item.classId === filters.classId) &&
      containsKeyword(item.subjectId, item.subjectName, item.classId, item.className, item.roomName)
  )
)
const filteredClasses = computed(() =>
  classes.value.filter(
    (item) =>
      (!filters.scienceName || item.scienceName === filters.scienceName) &&
      containsKeyword(item.classId, item.className, item.scienceName, item.courseName)
  )
)
const filteredSubjects = computed(() =>
  subjects.value.filter(
    (item) =>
      (!filters.scienceName || item.scienceName === filters.scienceName) &&
      containsKeyword(item.subjectId, item.subjectName, item.scienceName)
  )
)
const filteredStudents = computed(() =>
  students.value.filter(
    (item) =>
      (!filters.studentClassId || item.classId === filters.studentClassId) &&
      containsKeyword(item.studentId, item.fullName, item.email, item.mobile, item.classId, item.className)
  )
)
const filteredYears = computed(() => years.value.filter((item) => containsKeyword(item.yearId, item.yearName)))
const filteredSciences = computed(() =>
  sciences.value.filter((item) => containsKeyword(item.scienceId, item.scienceName, item.scienceShortName))
)
const filteredCohorts = computed(() =>
  cohorts.value.filter((item) => containsKeyword(item.courseId, item.courseName, item.startYear, item.finishYear))
)
const assignableStudents = computed(() => {
  const term = studentSearch.value.toLowerCase()
  return students.value.filter((item) => !term || `${item.fullName} ${item.studentId}`.toLowerCase().includes(term))
})
const formTitle = computed(
  () =>
    ({
      YEAR: 'Thêm năm học',
      SCIENCE: 'Thêm khoa',
      COHORT: 'Thêm khóa tuyển sinh',
      SUBJECT: 'Thêm môn học',
      CLASS: 'Thêm lớp hành chính',
      CLASS_SUBJECT: 'Mở môn học cho lớp',
      TIMETABLE: form.timetableId ? 'Cập nhật lịch học' : 'Thêm lịch học'
    })[form.entityType]
)

onMounted(load)

function mapRows(rows, mapping) {
  return (rows || []).map((row) =>
    Object.fromEntries(Object.entries(mapping).map(([key, names]) => [key, pick(row, ...names)]))
  )
}
async function load() {
  loading.value = true
  try {
    const data = await axiosClient.get('/academic/catalog', { params: { _fresh: Date.now() } })
    years.value = mapRows(pick(data, 'Years', 'years'), {
      dataGroupId: ['DataGroupID', 'dataGroupID'],
      yearId: ['YearID', 'yearID'],
      yearName: ['YearName', 'yearName'],
      startAt: ['StartAt', 'startAt'],
      finishAt: ['FinishAt', 'finishAt']
    })
    sciences.value = mapRows(pick(data, 'Sciences', 'sciences'), {
      scienceId: ['ScienceID', 'scienceID'],
      scienceName: ['ScienceName', 'scienceName'],
      scienceShortName: ['ScienceShortName', 'scienceShortName']
    })
    cohorts.value = mapRows(pick(data, 'Cohorts', 'cohorts'), {
      courseId: ['CourseID', 'courseID'],
      courseName: ['CourseName', 'courseName'],
      startYear: ['StartYear', 'startYear'],
      finishYear: ['FinishYear', 'finishYear']
    })
    classes.value = mapRows(pick(data, 'Classes', 'classes'), {
      classId: ['ClassID', 'classID'],
      className: ['ClassName', 'className'],
      scienceName: ['ScienceName', 'scienceName'],
      courseName: ['CourseName', 'courseName'],
      classSize: ['ClassSize', 'classSize'],
      studentCount: ['StudentCount', 'studentCount']
    })
    subjects.value = mapRows(pick(data, 'Subjects', 'subjects'), {
      subjectId: ['SubjectID', 'subjectID'],
      subjectName: ['SubjectName', 'subjectName'],
      scienceName: ['ScienceName', 'scienceName'],
      theoryQuantity: ['TheoryQuantity', 'theoryQuantity'],
      practiceQuantity: ['PracticeQuantity', 'practiceQuantity'],
      creditCount: ['CreditCount', 'creditCount']
    })
    teachers.value = mapRows(pick(data, 'Teachers', 'teachers'), {
      teacherId: ['TeacherID', 'teacherID'],
      userId: ['UserID', 'userID'],
      teacherName: ['TeacherName', 'teacherName']
    })
    students.value = mapRows(pick(data, 'Students', 'students'), {
      studentId: ['StudentID', 'studentID'],
      userId: ['UserID', 'userID'],
      fullName: ['FullName', 'fullName'],
      classId: ['ClassID', 'classID'],
      className: ['ClassName', 'className'],
      email: ['Email', 'email'],
      mobile: ['Mobile', 'mobile']
    })
    offerings.value = mapRows(pick(data, 'ClassSubjects', 'classSubjects'), {
      classSubjectId: ['ClassSubjectID', 'classSubjectID'],
      yearId: ['YearID', 'yearID'],
      yearName: ['YearName', 'yearName'],
      semester: ['Semester', 'semester'],
      classId: ['ClassID', 'classID'],
      className: ['ClassName', 'className'],
      subjectId: ['SubjectID', 'subjectID'],
      subjectName: ['SubjectName', 'subjectName'],
      teacherName: ['TeacherName', 'teacherName'],
      creditCount: ['CreditCount', 'creditCount'],
      theoryQuantity: ['TheoryQuantity', 'theoryQuantity'],
      practiceQuantity: ['PracticeQuantity', 'practiceQuantity'],
      onlineCourseId: ['OnlineCourseID', 'onlineCourseID'],
      onlineCourseTitle: ['OnlineCourseTitle', 'onlineCourseTitle'],
      chapterCount: ['ChapterCount', 'chapterCount'],
      lessonCount: ['LessonCount', 'lessonCount'],
      studentCount: ['StudentCount', 'studentCount']
    })
    timetables.value = mapRows(pick(data, 'Timetables', 'timetables'), {
      timetableId: ['TimetableID', 'timetableID'],
      classSubjectId: ['ClassSubjectID', 'classSubjectID'],
      yearId: ['YearID', 'yearID'],
      yearName: ['YearName', 'yearName'],
      semester: ['Semester', 'semester'],
      classId: ['ClassID', 'classID'],
      className: ['ClassName', 'className'],
      subjectId: ['SubjectID', 'subjectID'],
      subjectName: ['SubjectName', 'subjectName'],
      dayOfWeek: ['DayOfWeek', 'dayOfWeek'],
      startPeriod: ['StartPeriod', 'startPeriod'],
      endPeriod: ['EndPeriod', 'endPeriod'],
      startTime: ['StartTime', 'startTime'],
      endTime: ['EndTime', 'endTime'],
      roomName: ['RoomName', 'roomName'],
      effectiveFrom: ['EffectiveFrom', 'effectiveFrom'],
      effectiveTo: ['EffectiveTo', 'effectiveTo']
    })
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    loading.value = false
  }
}
function blankForm() {
  return {
    entityType: 'CLASS_SUBJECT',
    dataGroupId: 1,
    code: '',
    name: '',
    shortName: '',
    parentCode: '',
    startYear: new Date().getFullYear(),
    finishYear: new Date().getFullYear() + 4,
    startAt: '',
    finishAt: '',
    yearId: null,
    semester: null,
    classSubjectId: null,
    classId: '',
    subjectId: '',
    teacherId: '',
    classSize: 40,
    creditCount: 3,
    theoryQuantity: 30,
    practiceQuantity: 30,
    timetableId: null,
    dayOfWeek: null,
    startPeriod: 1,
    endPeriod: 3,
    startTime: '07:00',
    endTime: '09:30',
    roomName: '',
    effectiveFrom: '',
    effectiveTo: ''
  }
}
function openCreate(entityType) {
  Object.assign(form, blankForm(), { entityType })
  formModal.value = true
}
function openTimetable(item) {
  Object.assign(form, blankForm(), {
    entityType: 'TIMETABLE',
    timetableId: item.timetableId,
    classSubjectId: item.classSubjectId,
    dayOfWeek: item.dayOfWeek,
    startPeriod: item.startPeriod,
    endPeriod: item.endPeriod,
    startTime: timeText(item.startTime),
    endTime: timeText(item.endTime),
    roomName: item.roomName || '',
    effectiveFrom: item.effectiveFrom?.slice(0, 10) || '',
    effectiveTo: item.effectiveTo?.slice(0, 10) || ''
  })
  formModal.value = true
}
async function saveCatalog() {
  saving.value = true
  try {
    await axiosClient.post('/academic/catalog', {
      ...form,
      startAt: form.startAt || null,
      finishAt: form.finishAt || null,
      teacherId: form.teacherId || null,
      startTime: form.startTime ? `${form.startTime}:00` : null,
      endTime: form.endTime ? `${form.endTime}:00` : null,
      effectiveFrom: form.effectiveFrom || null,
      effectiveTo: form.effectiveTo || null
    })
    formModal.value = false
    await load()
    show('Đã lưu cấu trúc đào tạo.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function openAssign(item) {
  assignTarget.value = item
  selectedStudents.value = students.value
    .filter((student) => student.classId === item.classId)
    .map((student) => student.userId)
  studentSearch.value = ''
  assignModal.value = true
}
async function assignStudents() {
  saving.value = true
  try {
    await axiosClient.post('/academic/classes/students', {
      dataGroupId: 1,
      classId: assignTarget.value.classId,
      studentUserIds: selectedStudents.value
    })
    assignModal.value = false
    await load()
    show('Đã phân học viên vào lớp và tự ghi danh các môn LMS của lớp.')
  } catch (error) {
    show(error.message, 'danger')
  } finally {
    saving.value = false
  }
}
function dateText(value) {
  return value ? new Intl.DateTimeFormat('vi-VN').format(new Date(value)) : '—'
}
function dayLabel(value) {
  return weekDays.find((item) => item.value === Number(value))?.label || '—'
}
function timeText(value) {
  return value ? String(value).slice(0, 5) : '—'
}
function setViewMode(mode) {
  viewModes[activeTab.value] = mode
  window.localStorage.setItem(`cms-academic-view-${activeTab.value}`, mode)
}
function show(text, type = 'success') {
  message.value = text
  messageType.value = type
  window.scrollTo({ top: 0, behavior: 'smooth' })
}
</script>

<style scoped src="../../assets/css/pages/cms/academic-structure.css"></style>
<style scoped src="../../assets/css/pages/cms/academic-timetable.css"></style>
<style scoped src="../../assets/css/pages/cms/academic-dialogs.css"></style>
