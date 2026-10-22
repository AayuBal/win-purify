---
name: win-purify
description: Windows 极限减负与系统净化大师。具备“个人自用极速模式”与“付费客户商业交付模式”双通道架构。支持四维交互白名单探查、开发工程智能无损脱水（仅清依赖/缓存保护源码）、UE 引擎游戏微创手术（剥离 4K 可选材质包与着色器缓存）、Windows 核心与 DriverStore 驱动安全修剪、开机内存压制与 Bloatware 卸载、虚拟内存重平衡，并生成专业交付报告。
metadata:
  version: "1.0.0"
  author: "hzy"
  type: "system-optimization"
---

# win-purify：Windows 极限减负与系统净化大师

Windows 10 / 11 深度系统瘦身、C 盘数十 GB 级别极限回血、开机常驻内存降维打击与游戏/开发资产安全脱水的一站式专业工具。

---

## 1. 核心定位与双通道架构

为了同时支持**“日常自用免问询极速秒级优化”**与**“商业客户专业、零风险、高感知付费交付”**，本 Skill 采用双通道路由：

| 模式 | 触发命令 | 适用场景 | 执行策略 |
| :--- | :--- | :--- | :--- |
| **商业客户交付模式**（默认） | `$win-purify`<br/>`$win-purify --client` | 面向任何外部付费客户、朋友电脑维护 | **安全第一，必须执行「阶段零：四维白名单探查」**，绝不硬编码任何个人偏好，先探查客户游戏/网盘/远程/开发环境，确认后执行并输出《交付报告》。 |
| **个人自用极速模式** | `$win-purify --self` | 用户本人工作站日常快速减负 | **跳过所有问卷**，直接加载预设档案：16GB RAM + NVMe 基线、火绒/CC Switch/UU远控/GoogleDrive/飞书白名单、三角洲 4K Pak 剥离、前端废弃工程脱水。 |

---

## 2. 商业客户交付模式 (`--client`) 标准操作规程 (SOP)

### 阶段零：四维交互式白名单探查 (Client Discovery Engine)

面向付费客户时，**切忌一上来就删文件或停服务**。必须先调用 `ask_question` 或结构化问询完成四维画像：

#### 维度 1：游戏与反作弊审查
- **问询**：“平时主要玩哪些游戏？（例如：三角洲行动、瓦罗兰特、无畏契约、CS2、守望先锋、APEX、黑神话、COD等）”
- **安全红线**：
  - 含有腾讯 ACE、拳头 Vanguard 等内核级反作弊的游戏，**严禁修改内核分页/文件系统缓存注册表**（详见 [references/safety-and-anticheat.md](references/safety-and-anticheat.md)）。
  - 若包含三角洲行动或 COD，提示客户是否愿意剔除“无用的 4K 超清大包”（可直接腾出 15~20 GB）。

#### 维度 2：生产力与常驻工具审查
- **问询**：“有哪些软件是必须开机自启、随时在后台待命的？（例如网盘同步、远程控制、网络加速/代理、企业办公等）”
- **记录豁免**：客户确认的工具（如坚果云、ToDesk、向日葵、网易UU、各类网盘）一律加入白名单，禁止优化其自启项。

#### 维度 3：技术与设计工程环境审查
- **问询**：“电脑上是否有正在进行的编程开发（Node.js, Python, Java, Docker）或视频设计项目？”
- **规则**：
  - 非技术用户：跳过工程脱水，聚焦系统底层与游戏缓存。
  - 技术用户：开启智能脱水流程，告知其“**源码、Markdown 与 Git 历史 100% 绝对保护，仅清理可再生的 `node_modules` 与缓存**”。

#### 维度 4：客户激进等级确认
- **保守级**：清临时垃圾、浏览器旧缓存、锁定崩溃转储，不动自启与服务。
- **均衡级（推荐商业交付）**：DISM 系统库重构、DriverStore 冗余显卡驱动修剪、开机非必要自启治理、关闭流氓唤醒任务。
- **极客级**：Win11 原生预装 Bloatware 卸载、虚拟内存锁额、代码工程深度脱水。

---

### 阶段一：硬核非破坏性磁盘瘦身 (Disk Surgery)

按客户确认的方案，调用对应脚本或执行命令：

#### 1. 开发工程智能脱水 (Code Dehydration)
对客户指定的代码目录运行脱水逻辑：
```powershell
# 仅扫描 60 天以上未修改项目中的巨大依赖包，不碰任何源码
Get-ChildItem -Path $DevPath -Directory -Recurse -Depth 3 -Filter "node_modules" | ...
```
- 清理前端死工程的 `node_modules`, `.next`, `dist`, `.turbo`。
- 清理 Python 的 `__pycache__`, `.venv`, `.pytest_cache`。
- 清理 VSCode 孤立扩展更新残留缓存（`~/.vscode/extensions/.` 开头的隐藏目录）。

#### 2. 大型游戏微创手术 (Game Asset Surgery)
- **UE 引擎 Optional 4K Paks 识别**：
  - 检索大型游戏目录中的 `*optional*.pak` 和 `.sig` 文件。
  - 经客户确认后安全剔除，直接回血 15 ~ 20 GB。
- **着色器坏死缓存清理**：
  - 清理 NVIDIA/AMD 旧着色器缓存（`%LocalAppData%\D3DSCache`、`%LocalAppData%\NVIDIA\DXCache`）。
  - 清理游戏专用着色器缓存（如三角洲行动的 `Saved\PSOCache`）。
- **废弃创意工坊地图清理**：
  - 清理 Steam `steamapps\workshop\content\` 中已卸载游戏的残留大地图。

#### 3. Windows 系统底层与驱动安全修剪
- **WinSxS 重置基准**：
  ```cmd
  dism.exe /Online /Cleanup-Image /StartComponentCleanup /ResetBase
  ```
- **DriverStore 冗余驱动包安全移除**：
  - 利用系统原生 `pnputil` 枚举非活动旧驱动。
  - **严禁带 `/force` 参数**，系统将自动拒绝删除任何当前正在使用的驱动，100% 零风险：
  ```cmd
  pnputil /delete-driver oemXX.inf
  ```
- **崩溃转储策略收窄**：
  - 将 `HKEY_LOCAL_MACHINE\SYSTEM\CurrentControlSet\Control\CrashControl` 下的 `CrashDumpEnabled` 设为 `3`（小内存转储 256KB），粉碎全量大转储。

---

### 阶段二：开机常驻内存降维打击 (RAM Streamlining)

#### 1. 开机自启非核心应用治理
- 仅保留客户白名单，禁用后台偷偷常驻的 Electron/Chromium 壳程序（各种助手、自动更新器、未使用的聊天软件）。

#### 2. Windows 11 原生 Bloatware 卸载
针对极客/均衡级，批量静默卸载微软原生无用臃肿应用：
```powershell
Get-AppxPackage *YourPhone* | Remove-AppxPackage
Get-AppxPackage *Microsoft.Windows.Search* | Remove-AppxPackage
Get-AppxPackage *Xbox* | Remove-AppxPackage
Get-AppxPackage *ZuneMusic* | Remove-AppxPackage
Get-AppxPackage *WindowsFeedbackHub* | Remove-AppxPackage
```

#### 3. 后台流氓唤醒与静默驻留扼杀
- **Edge 浏览器驻留关闭**：
  - 注册表配置 `BackgroundModeEnabled = 0` 与 `StartupBoostEnabled = 0`，防止关闭 Edge 后后台常驻 10+ 个进程。
- **计划任务流氓唤醒排查**：
  - 禁用 WPS、各类输入法、第三方软件的 Update Task 与定时弹出任务。
- **SysMain 服务评估**：
  - 若客户为 NVMe SSD + 16GB 以上内存，停止并禁用 `SysMain`，显著减少随机磁盘 IO 与内存颠簸。

---

### 阶段三：交付成果汇报报告 (Delivery Report)

商业交付完成后，自动生成排版美观的交付成果报告，交付给客户：

```markdown
# 💻 PC 极限减负与深度净化交付报告

尊敬的客户，您的电脑已完成全套深度优化与安全减负，具体战果如下：

## 1. 核心战果统计
- 💽 **C 盘空间回收**：释放约 **[XX] GB**（优化前剩余 [XX] GB ➡️ 优化后剩余 [XX] GB）
- 🚀 **开机常驻内存压制**：降低约 **[XX] GB**（开机闲置占用从 [XX]% 下降至 [XX]%）
- 🛡️ **清理项目安全性**：100% 通过无损校验，业务文件与游戏存档零影响

## 2. 执行动作明细
- [x] **驱动仓库瘦身**：通过 Windows PnP 原生机制安全剔除了 [X] 个过期旧版显卡驱动包
- [x] **游戏/大文件微创**：移除了未使用的 [游戏名] 4K 超清大包与失效着色器缓存
- [x] **后台驻留治理**：拦截了 [X] 个偷偷开机自启的后台进程与流氓唤醒任务
- [x] **开发资产脱水**：（若有）安全剥离了废弃项目的依赖包，源码完全完好
- [x] **白名单保留项**：[客户指定的白名单列表] 保持正常常驻运行

## 3. 后续维护建议
- 建议重启一次电脑，以使 Windows 驱动仓库与虚拟内存配额完全生效。
```

---

## 3. 个人专属极速模式 (`--self`) 预置档案

当用户本人调用 `$win-purify --self` 时，执行以下固定策略：

```yaml
Hardware Profile:
  RAM: 16 GB Physical
  Disk: High-Speed NVMe SSD
  Pagefile Strategy: Fixed 4096 MB ~ 8192 MB (回血 ~10 GB C盘)

Must-Keep Whitelist (绝对保护，保持自启/常驻):
  - 火绒安全 (Huorong)
  - CC Switch (代理切换)
  - UU 远程控制 (UU Remote)
  - 谷歌云端硬盘 (GoogleDriveFS)
  - 飞书 (Feishu)

Target Game Micro-Surgery:
  - 三角洲行动 (Delta Force): 
    - 自动探查 Content\Paks\ 下的 *optional*.pak 并移除
    - 自动清理 Saved\PSOCache
  - 守望先锋 (Overwatch): 保护着色器与关键资产
  - 无畏契约 (Valorant): 保护 Riot Vanguard，严禁修改反作弊敏感注册表

Dev Dehydration Target:
  - 扫描本地未活跃前端项目，安全脱水 node_modules
  - 清理 VSCode 孤立更新扩展缓存 (.*) 与废弃全局 npm 包
```

---

## 4. 安全红线与绝对禁忌清单 (Safety Rules)

在任何模式下，**严禁触犯以下禁忌**：

1. **绝对禁忌带 `/force` 强制删除驱动**：
   - 驱动清理必须使用标准的 `pnputil /delete-driver <oem#.inf>`。系统自动阻断正在使用的驱动删除。带 `/force` 可能导致蓝屏。
2. **绝对禁忌直接关闭虚拟内存 (Pagefile)**：
   - 16GB 内存关闭分页文件会导致大型竞技游戏（三角洲、APEX、无畏契约）和 Chrome 极速爆内存崩溃，必须采用上限收紧方案（如 4~8GB）。
3. **绝对禁忌碰反作弊敏感注册表**：
   - 严禁开启 `DisablePagingExecutive = 1` 或 `LargeSystemCache = 1`。在现代 Win11 与腾讯 ACE / 拳头 Vanguard 环境下极易引发反作弊蓝屏与微卡顿。
4. **绝对禁忌误伤开发源码**：
   - 脱水仅限 `node_modules`、`.venv`、`build`、`dist`，**严禁删除任何 `.git`、配置文件或源代码文件**。
