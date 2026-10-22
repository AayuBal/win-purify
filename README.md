# Win-Purify

Windows 10 / 11 系统清理与资源优化工具。既支持作为 Antigravity Skill 在对话中由 Agent 调度执行，也可以作为独立的 PowerShell 脚本在终端中运行。

[![OS - Windows 10 | 11](https://img.shields.io/badge/OS-Windows%2010%20%7C%2011-0078D6?style=flat-square&logo=windows&logoColor=white)](https://microsoft.com/windows)
[![PowerShell - 5.1+](https://img.shields.io/badge/PowerShell-5.1%2B%20%7C%207%2B-5391FE?style=flat-square&logo=powershell&logoColor=white)](https://learn.microsoft.com/powershell/)
[![License - MIT](https://img.shields.io/badge/License-MIT-green?style=flat-square)](LICENSE)

---

## 工具定位

Win-Purify 用于清理 Windows 系统中容易被忽略的大体积冗余文件，并治理后台常驻进程。它主要处理以下五类资源占用：

1. **历史显卡驱动残留**：显卡驱动每次更新后，旧版完整安装包（单个约 2.5 ~ 3 GB）会滞留在 `DriverStore\FileRepository` 中，系统默认不主动清理。
2. **游戏未使用的 4K 贴图包**：部分虚幻引擎（Unreal Engine）游戏（如《三角洲行动》等）默认捆绑了 4K/UHD 可选材质包，在 1080P 或 2K 竞技画质下并不生效，单项占用常达 15 ~ 20 GB。
3. **长期闲置项目的开发依赖**：本地已归档或长期未活跃的前端与 Python 项目中，累积了大量可再生的 `node_modules`、`.venv` 与构建缓存。
4. **非必要后台驻留与流氓唤醒**：各类软件自带的开机自启动更新器、Edge 浏览器关闭后的后台驻留进程、第三方软件的定时弹窗与唤醒计划任务。
5. **动态页面文件（虚拟内存）无上限膨胀**：在 16GB 物理内存环境下，Windows 默认将页面文件动态分配至 14 ~ 18 GB，挤占 C 盘空间。

---

## 安全边界与反作弊兼容原则

本工具不采用任何网络流传的玄学注册表修改，所有清理与配置调整均有明确的系统内核机制支持：

- **驱动删除不加 `/force`**：驱动仓库清理严格调用 Windows 原生 `pnputil /delete-driver <oem#.inf>`，不附加 `/force` 参数。Windows PnP 机制会自动检测驱动状态，若该驱动当前正在被硬件设备使用，系统内核会直接拒绝删除；只有确认未被任何硬件绑定的旧版本才会被移除。
- **开发依赖清理不碰源码**：工程脱水脚本仅匹配 `node_modules`、`.venv`、`dist`、`.next`、`__pycache__` 等由包管理器生成的可再生文件夹。**绝不修改、移动或删除任何源代码文件、Markdown 笔记、配置文件以及 `.git` 历史记录**。
- **页面文件不直接关闭**：反作弊驱动（腾讯 ACE、拳头 Vanguard）与现代 DirectX 12 游戏启动时依赖虚拟内存提交额度（Commit Charge）。直接禁用分页文件会导致游戏报内存不足闪退。本工具仅将 16GB 内存主机的页面文件上限固定为 4096 MB ~ 8192 MB，既能为 C 盘回收空间，又满足 Commit 额度需求。
- **不修改反作弊敏感注册表**：坚决不开启 `DisablePagingExecutive = 1`（在 16GB 环境下会导致驱动锁页内存竞争，诱发 ACE/Vanguard 蓝屏）与 `LargeSystemCache = 1`（将系统改为服务器调度模型，压缩游戏可用前台物理内存）。

---

## 实测清理效果

测试环境：Windows 11 专业版，Intel Core i7，16GB 物理内存，NVMe SSD。

| 检查项 | 优化前状态 | 优化后状态 | 实际变化 | 说明 |
| :--- | :--- | :--- | :--- | :--- |
| **C 盘可用空间** | 38.65 GB | 114.73 GB | 净增约 **76.08 GB** | 重启系统使页面文件收窄生效后，剩余空间达到 ~128 GB |
| **开机待机内存** | 8.2 GB (52%) | 3.6 GB (23%) | 降低约 **4.6 GB** | 禁用 8 个非核心启动项、停用 Edge 后台驻留与无用计划任务 |
| **游戏文件占用** | 包含 4K Pak 与旧着色器 | 剔除 4K Pak，重构着色器 | 释放 **23.11 GB** | 移除了《三角洲行动》`*optional*.pak` (19.83 GB) 与 PSOCache |
| **驱动仓库体积** | 存在多个旧版 NVIDIA 包 | 仅保留当前活动显卡驱动 | 释放 **2.60 GB** | 移除了 1 个已解绑的历史版本驱动包 |
| **前端工程依赖** | 5 个长期未动的测试工程 | 完成依赖脱水，源码完好 | 释放 **10.20 GB** | 随时可通过 `npm install` 重新安装依赖 |

---

## 运行模式与交互机制

作为 Antigravity Skill 使用时，系统提供两种运行模式：

### 1. 商业交付模式（默认模式）
用于为他人或客户优化电脑。执行前必须先完成四项边界探查，禁止在未确认前修改用户系统：
1. **游戏与反作弊排查**：了解用户常玩游戏。若包含带内核反作弊的游戏，严格锁定内核参数；若包含支持可选材质的游戏，提示是否剔除。
2. **常驻与生产力白名单**：确认网盘同步（坚果云/百度网盘/OneDrive/Google Drive）、远程控制（ToDesk/向日葵/UU远程）、网络代理与办公通讯工具，一律加入白名单不予精简。
3. **开发环境排查**：确认是否存在编程或设计资产。非技术用户跳过代码脱水；开发者需确认具体目录后仅脱水依赖。
4. **清理级别确认**：提供保守级（仅清缓存与临时文件）、均衡级（推荐，修剪驱动与自启）、极客级（卸载 Win11 预装应用、重平衡虚拟内存）。

### 2. 个人自用极速模式 (`--self`)
用于开发者本人设备。跳过所有问卷流程，直接载入本地预设配置：
- 硬件基线：16GB 物理内存 + 高速 NVMe SSD，页面文件锁定为 4096 ~ 8192 MB；
- 专属白名单：火绒、CC Switch、UU 远程控制、Google Drive、飞书；
- 专属游戏处理：自动定位并清理《三角洲行动》`*optional*.pak` 与 `PSOCache`；
- 专属工程脱水：自动扫描本地废弃的前端测试目录，清理 `node_modules` 与 VSCode 扩展更新暂存目录。

---

## 脚本清单与终端使用方法

所有脚本均位于 `scripts/` 目录下，采用原生 PowerShell 5.1 语法编写，无第三方模块依赖。请在以**管理员身份运行**的 PowerShell 中执行：

### 1. 系统状态与健康体检
只读检测，不修改任何系统状态。输出 C 盘空间、内存、页面文件、冗余显卡驱动数量与开机自启动项统计：
```powershell
.\scripts\Scan-PCStatus.ps1
```

### 2. 开发工程无损脱水
扫描指定路径下超过 30 天未更新的目录，识别可脱水的依赖包：
```powershell
# 仅扫描并输出体积统计（默认安全模式，不删除任何文件）
.\scripts\Dehydrate-DevProjects.ps1 -RootPath "D:\Projects"

# 确认脱水，删除匹配到的依赖文件夹
.\scripts\Dehydrate-DevProjects.ps1 -RootPath "D:\Projects" -Execute
```

### 3. 驱动仓库安全瘦身
枚举已安装的第三方显卡驱动包，安全调用 `pnputil /delete-driver`：
```powershell
# 预演模式，仅查看哪些驱动包将被检查
.\scripts\Clean-DriverStore.ps1 -WhatIf

# 正式执行清理（系统内核自动保护正在使用的驱动）
.\scripts\Clean-DriverStore.ps1
```

### 4. 游戏可选材质与着色器缓存清理
识别虚幻引擎游戏目录中的可选 4K 贴图包与损坏着色器缓存：
```powershell
# 仅扫描已安装游戏的 Pak 文件与 DirectX 缓存
.\scripts\Trim-GameAssets.ps1

# 确认剥离 4K 可选大包并清空旧着色器缓存
.\scripts\Trim-GameAssets.ps1 -Execute
```

### 5. 系统底层核心与驻留进程优化
配置崩溃转储为 Minidump (256KB)、封堵 Edge 浏览器后台常驻模式、停用流氓唤醒计划任务：
```powershell
# 基础核心优化
.\scripts\Optimize-WindowsCore.ps1

# 包含卸载 Windows 11 原生预装应用（Xbox、手机连接、小组件等）与停用 SysMain
.\scripts\Optimize-WindowsCore.ps1 -RemoveBloatware -DisableSysMain
```

---

## 交付验收报告模板

在完成客户交付后，Skill 会自动生成包含具体指标的数据报告供客户核对：

```markdown
# PC 系统优化与减负交付报告

- 操作系统：Windows 11 专业版
- 交付状态：已完成安全校验，业务文件与游戏存档保持原样

## 1. 核心资源变化
- C 盘可用空间：从 [XX] GB 提升至 [XX] GB（净释放约 [XX] GB）
- 开机闲置内存：从 [XX] GB ([XX]%) 下降至 [XX] GB ([XX]%)
- 驱动仓库清理：通过 Windows PnP 机制安全移除了 [X] 个历史显卡驱动包
- 后台驻留优化：关闭了 [X] 个非必要自启进程与后台静默驻留任务

## 2. 资产保留确认
- 游戏环境：已对 [游戏名称] 反作弊驱动做环境隔离，核心设置完好
- 生产力工具：已保留 [白名单应用名称] 开机自启与后台同步
- 开发与文档：所有源代码、配置文件与文档完全保留

## 3. 后续建议
建议重启一次电脑，使驱动仓库的物理空间释放与页面文件配额正式生效。
```

---

## 文件结构

```
win-purify/
├── SKILL.md                          # Antigravity Skill 调度规则与问答 SOP
├── README.md                         # 项目技术文档与使用指南
├── LICENSE                           # MIT 许可证
├── scripts/                          # 原生 PowerShell 5.1 微创清理脚本
│   ├── Scan-PCStatus.ps1             # 系统健康与资源体检
│   ├── Clean-DriverStore.ps1         # 驱动仓库旧版驱动安全清理
│   ├── Dehydrate-DevProjects.ps1     # 开发工程依赖无损脱水
│   ├── Trim-GameAssets.ps1           # 游戏可选材质包与着色器清理
│   └── Optimize-WindowsCore.ps1      # 系统崩溃转储与后台常驻优化
└── references/                       # 技术依据与业务操作规程
    ├── safety-and-anticheat.md       # 反作弊兼容说明与注册表安全红线
    └── client-inquiry-guide.md       # 客户探查四步法与沟通模版
```

---

## 许可证

本项目遵循 [MIT 许可证](LICENSE)。
