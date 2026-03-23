# 小说阅读器 - 菜单显示时屏蔽滚动和翻页操作实现计划

## [ ] 任务 1: 修改滚动模式下的滚动行为
- **Priority**: P0
- **Depends On**: None
- **Description**: 
  - 在`_buildMainContentWithScrollView`方法中，根据`_showMenu`状态控制CustomScrollView的physics属性
  - 当菜单显示时，设置为NeverScrollableScrollPhysics
  - 当菜单关闭时，恢复为默认的滚动物理特性
- **Acceptance Criteria Addressed**: AC-1, AC-3, AC-4
- **Test Requirements**:
  - `human-judgment` TR-1.1: 菜单显示时，CustomScrollView无法滚动
  - `human-judgment` TR-1.2: 菜单关闭时，CustomScrollView可以正常滚动
  - `human-judgment` TR-1.3: 菜单动画流畅
- **Notes**: 使用AnimatedBuilder或直接在build方法中根据_showMenu状态设置physics

## [ ] 任务 2: 修改TextPaginator组件，添加禁止翻页参数
- **Priority**: P0
- **Depends On**: None
- **Description**:
  - 在TextPaginator组件中添加一个`enablePaging`参数，默认为true
  - 根据该参数控制是否响应翻页手势
  - 当enablePaging为false时，禁用左右点击翻页功能
- **Acceptance Criteria Addressed**: AC-2, AC-3, AC-4
- **Test Requirements**:
  - `human-judgment` TR-2.1: 当enablePaging为false时，TextPaginator无法翻页
  - `human-judgment` TR-2.2: 当enablePaging为true时，TextPaginator可以正常翻页
  - `human-judgment` TR-2.3: 菜单动画流畅
- **Notes**: 修改TextPaginator的手势检测逻辑，根据enablePaging参数决定是否处理翻页手势

## [ ] 任务 3: 在分页模式下传递禁止翻页参数
- **Priority**: P0
- **Depends On**: 任务 2
- **Description**:
  - 在`_buildMainContentWithPaginator`方法中，根据`_showMenu`状态传递enablePaging参数
  - 当菜单显示时，传递false
  - 当菜单关闭时，传递true
- **Acceptance Criteria Addressed**: AC-2, AC-3, AC-4
- **Test Requirements**:
  - `human-judgment` TR-3.1: 菜单显示时，TextPaginator无法翻页
  - `human-judgment` TR-3.2: 菜单关闭时，TextPaginator可以正常翻页
  - `human-judgment` TR-3.3: 菜单动画流畅
- **Notes**: 确保参数传递正确，与_showMenu状态同步

## [ ] 任务 4: 测试验证
- **Priority**: P0
- **Depends On**: 任务 1, 任务 2, 任务 3
- **Description**:
  - 测试滚动模式下菜单显示时的滚动行为
  - 测试分页模式下菜单显示时的翻页行为
  - 测试菜单关闭后的恢复行为
  - 测试菜单动画的流畅性
- **Acceptance Criteria Addressed**: AC-1, AC-2, AC-3, AC-4
- **Test Requirements**:
  - `human-judgment` TR-4.1: 滚动模式下菜单显示时禁止滚动
  - `human-judgment` TR-4.2: 分页模式下菜单显示时禁止翻页
  - `human-judgment` TR-4.3: 菜单关闭后恢复正常操作
  - `human-judgment` TR-4.4: 菜单动画流畅
- **Notes**: 确保所有场景都测试到，包括菜单显示/隐藏的动画过程