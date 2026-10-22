# 安全红线与反作弊兼容指南 (Safety & Anti-Cheat Compatibility)

本指南总结了在 Windows 10 / 11 下执行深度精简、服务优化、注册表调优时的**硬核安全边界**。  
所有参与交付此 Skill 的 Agent 必须严格恪守以下原则，**绝对不触犯红线**。

---

## 一、网络竞技反作弊系统禁忌矩阵

现代主流大型竞技网游普遍采用了内核级（Kernel-level / Ring 0）反作弊驱动：
- **腾讯 ACE (Anti-Cheat Expert)**：三角洲行动、英雄联盟、无畏契约国服、CFHD
- **拳头 Vanguard (vgk.sys)**：无畏契约 (Valorant)
- **Easy Anti-Cheat (EAC)**：APEX 英雄、堡垒之夜、战地 2042
- **BattlEye (BEDaisy.sys)**：绝地求生 (PUBG)、彩虹六号：围攻

### 🚫 严禁开启/修改的危险注册表与系统参数：

| 危险参数 | 常见网络传言 | 真实致命后果 | 禁忌等级 |
| :--- | :--- | :--- | :--- |
| `DisablePagingExecutive = 1` | “把内核常驻物理内存，减少微卡顿” | 在 16GB 物理内存环境下，会导致驱动锁页内存竞争。一旦 ACE 或 Vanguard 申请内核页失败，**直接引发蓝屏（BSOD: PAGE_FAULT_IN_NONPAGED_AREA 或 CRITICAL_STRUCTURE_CORRUPTION）**。 | 🛑 **绝对禁止** |
| `LargeSystemCache = 1` | “扩大系统文件缓存，提高磁盘读取” | 将 Windows 调度器强行切换为“服务器工作站模型”，优先把物理内存分配给文件缓存，**严重挤压前台游戏进程的可用内存**，导致三角洲、APEX 出现周期性大幅掉帧、丢帧。 | 🛑 **绝对禁止** |
| **直接禁用虚拟内存 (Pagefile = 0)** | “内存够用就关虚拟内存，减少磁盘读写” | 极其危险！DirectX 12 现代游戏（虚幻引擎、寒霜引擎等）与反作弊驱动启动时，会请求预留 Commit Charge 虚拟内存提交额度。**关闭虚拟内存会导致 Commit 爆满，直接闪退或报 Out of Memory 崩溃**。 | 🛑 **绝对禁止** |
| `IoPageLockLimit` / `IRQPriority` | “提升网卡/GPU 中断优先级” | 远古 WinXP/Win7 时代的玄学调优，在 Win11 WDDM 3.x 下完全失效，甚至干扰 Windows 硬件调度器与反作弊自检。 | 🛑 **绝对禁止** |

---

## 二、DriverStore 驱动仓库瘦身安全机制

- **存放路径**：`C:\Windows\System32\DriverStore\FileRepository`
- **为什么冗余**：显卡厂商（尤其 NVIDIA）每次升级驱动，都会将完整的 2.5~3 GB 驱动包完整复制一份到此处，且 Windows 默认不清理历史旧包。
- **安全删除唯一合规命令**：
  ```cmd
  pnputil /delete-driver oemXX.inf
  ```
- **核心安全铁律**：**绝对不要添加 `/force` 参数！**
  - 不加 `/force` 时：Windows PnP 内核在执行删除前，会自动检测该驱动包是否正在被当前任何硬件设备绑定使用。如果该驱动处于“活动状态”，系统会直接拒绝删除（返回 *in use* 或 *failed*）。
  - 加了 `/force` 时：会强行卸除正在运行的显卡驱动，导致屏幕黑屏、驱动崩溃甚至系统无法正常引导。

---

## 三、代码工程脱水安全原则 (Code Dehydration Safety)

- **只脱水依赖，绝不碰源码**：
  - 允许清理的目标：`node_modules`、`.venv`、`dist`、`build`、`.next`、`.turbo`、`__pycache__`、VSCode 扩展更新暂存目录（`~/.vscode/extensions/.`）。
  - **绝对保护的目标**：任何 `.git` 文件夹、`.env` 配置文件、项目源代码（`.js`, `.ts`, `.py`, `.rs`, `.go` 等）、文档资产（`.md`, `.pdf`, `.png`）。
- **可复原性标准**：
  - 任何被脱水的工程，用户只需在根目录下执行原生包管理器安装命令（如 `npm install`、`pnpm i`、`poetry install`），即可 100% 无损重新拉取依赖运行。
