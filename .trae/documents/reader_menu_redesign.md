# ReaderMenu 设置面板重新设计方案

## 背景

多次修改 `_buildFontFamilySelector` 和 `_buildThemeSelector` 中的 ListView 布局问题均未解决，需要重新设计字体和主题切换的 UI。

## 当前数据

### 字体列表 (5个)
- system (系统默认)
- serif (衬线体)
- sans-serif (无衬线体)
- monospace (等宽字体)
- cursive (手写体)

### 主题列表 (5个)
- 护眼 (bg: #F0F8F0, text: #2E7D32)
- 羊皮纸 (bg: #F5F0E6, text: #4A4A4A)
- 夜间 (bg: #1A1A1A, text: #E0E0E0)
- 白色 (bg: #FFFFFF, text: #333333)
- 深蓝 (bg: #E3F2FD, text: #1976D2)

## 实施方案

### 1. 删除问题代码

删除以下两个方法：
- `_buildFontFamilySelector` (约第257-310行)
- `_buildThemeSelector` (约第658-726行)

### 2. 修改 `_buildSettingsPanel`

移除对已删除方法的调用：
- 删除 `RepaintBoundary(child: _buildFontFamilySelector(context, data))`
- 删除 `RepaintBoundary(child: _buildThemeSelector(context, data))`

### 3. 新设计方案：使用下拉选择框 (DropdownButton)

在 `_buildSettingsPanel` 中直接添加两个 DropdownButton：

#### 字体选择
```dart
Row(
  children: [
    Text('字体', style: TextStyle(fontSize: 14, color: SettingsService.menuTextColor)),
    SizedBox(width: 16),
    Expanded(
      child: DropdownButton<String>(
        value: data.fontFamily,
        isExpanded: true,
        dropdownColor: SettingsService.menuDividerColor,
        style: TextStyle(fontSize: 14, color: SettingsService.menuTextColor),
        items: SettingsService.fontFamilies.map((font) {
          return DropdownMenuItem(
            value: font,
            child: Text(SettingsService.fontFamilyNames[font]!),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            context.read<ReaderProvider>().setFontFamily(value);
          }
        },
      ),
    ),
  ],
)
```

#### 主题选择
```dart
Row(
  children: [
    Text('主题', style: TextStyle(fontSize: 14, color: SettingsService.menuTextColor)),
    SizedBox(width: 16),
    Expanded(
      child: DropdownButton<int>(
        value: data.themeIndex,
        isExpanded: true,
        dropdownColor: SettingsService.menuDividerColor,
        style: TextStyle(fontSize: 14, color: SettingsService.menuTextColor),
        items: SettingsService.themes.map((theme) {
          return DropdownMenuItem(
            value: SettingsService.themes.indexOf(theme),
            child: Row(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: ColorUtils.parseColor(theme['bg']!),
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: SettingsService.menuDividerColor),
                  ),
                ),
                SizedBox(width: 8),
                Text(theme['name']!),
              ],
            ),
          );
        }).toList(),
        onChanged: (value) {
          if (value != null) {
            context.read<ReaderProvider>().setTheme(value);
          }
        },
      ),
    ),
  ],
)
```

## 实施步骤

1. 删除 `_buildFontFamilySelector` 方法
2. 删除 `_buildThemeSelector` 方法
3. 修改 `_buildSettingsPanel`，添加 DropdownButton 实现的字体和主题选择
4. 运行 flutter analyze 验证

## 优点

- 使用 DropdownButton 避免了在 Row 中使用 ListView 的布局问题
- 代码更简洁，更易维护
- 用户体验良好，节省空间
