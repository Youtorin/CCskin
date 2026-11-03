# 上游关系与致谢

CCskin 根据「月白龙语」HTML 原型独立实现 Windows 主题接入。下表区分设计参考、媒体来源与代码依赖，不将本项目描述为上游官方分支或授权产品。

| 项目 | 与 CCskin 的关系 |
| --- | --- |
| [Fei-Away/Codex-Dream-Skin](https://github.com/Fei-Away/Codex-Dream-Skin) | 原始 Dream Skin 项目；参考保留原生界面、外置主题与本机 CDP 的接入思路，不复制安装器实现，也不依赖其管理器或主题包格式 |
| [EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose) | 上述项目的社区分支；旧地址 `EmiyaKatuz/Codex-Dream-Skin` 现重定向至此，用作皮肤表现参考，不包含该分支的角色素材或安装器 |
| [mytjxs/codex-startup-animation](https://github.com/mytjxs/codex-startup-animation) | 启动视频的直接来源，使用 v1.0.0 MP4，不复制或执行其 EXE、C# 启动器和安装脚本 |
| [lokicorvus/crosspet](https://github.com/lokicorvus/crosspet) | HTML 演示伴宠素材来源，不包含 CrossPet 应用代码，也不作为原生主题的 v2 图集 |
| [codex-pets.net / voira-chatgpt](https://codex-pets.net/api/pets/voira-chatgpt/share-data) | StephenQiu 发布的动画图集及描述文件来源，不复制网站、服务端或 CLI 实现 |
| [GenderSwapAI GPT 角色页](https://genderswapai.com/zh-CN/ai-gijinka/gpt) | 首页立绘获取渠道与角色来源资料，不镜像整站图库，也不将聚合站视作所有作品的权利人 |

## 许可对应关系

2026-11-03 复核时，两个 Dream Skin 仓库的代码许可证均为 MIT。CCskin 的原创代码和原创文字文档选择同一 [MIT 许可](../LICENSE)；这是本项目对原创部分的授权，不将参考关系表述为代码继承或上游背书。

| 上游 | 核对依据 | 在 CCskin 中的处理 |
| --- | --- | --- |
| Fei-Away/Codex-Dream-Skin | [MIT，固定提交 `6fc42df48a6a5365011f55cc349e20c038e56d1d`](https://github.com/Fei-Away/Codex-Dream-Skin/blob/6fc42df48a6a5365011f55cc349e20c038e56d1d/LICENSE) | 接入思路参考；本项目原创代码采用相同的 MIT 许可 |
| EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose | [MIT，固定提交 `46d24a75de5781e99ada0ea880887ce62c870e12`](https://github.com/EmiyaKatuz/Codex-Dream-Skin-Needy-Girl-Overdose/blob/46d24a75de5781e99ada0ea880887ce62c870e12/LICENSE) | 皮肤表现参考；未引入该分支的代码或素材 |
| CrossPet 角色素材 | [CC BY-NC-SA 4.0，固定提交 `6e98970f6ff9b44e8ac85215241cabcd78f67d92`](https://github.com/lokicorvus/crosspet/blob/6e98970f6ff9b44e8ac85215241cabcd78f67d92/characters/LICENSE.md) | 对应图片与美术改编保留原许可、署名和修改说明，随附 [上游声明](../licenses/CrossPet-art-NOTICE.md) 及 [许可全文](../licenses/CC-BY-NC-SA-4.0.txt) |
| mytjxs/codex-startup-animation | [仓库说明，固定提交 `9ea3b32b4e53f2d9db5d54265f6341b63aee5c04`](https://github.com/mytjxs/codex-startup-animation/blob/9ea3b32b4e53f2d9db5d54265f6341b63aee5c04/README.md)；使用媒体版本 v1.0.0 | 未确认明确的媒体再分发许可；视频和海报不纳入 MIT |
| StephenQiu 的 voira-chatgpt | [发布元数据](https://codex-pets.net/api/pets/voira-chatgpt/share-data)，素材版本 `1793361924612` | 本次响应未提供许可字段；原包也未附独立许可，图集与描述文件不纳入 MIT |
| ZipZipPipe / GenderSwapAI 角色资料 | [角色页](https://genderswapai.com/zh-CN/ai-gijinka/gpt) 及其指向的 [原始发布帖](https://www.bilibili.com/opus/1233069202138464289) | 保留作者与获取渠道，未确认的图片许可不推定为 MIT 或 CrossPet 的 CC 许可 |

上述 Dream Skin 提交仅固定本次许可核对的依据，不表示 CCskin 基于这些代码版本开发。MIT 不要求独立实现的项目必须采用同一许可，本项目按维护者的选择保持一致。未来实际引入上游代码时，应记录具体文件、提交和修改，保留上游版权声明及完整许可通知，不能只留下本项目署名。上游软件代码的许可不自动覆盖第三方角色、图片、视频或商标。

感谢 Fei-Away 和 EmiyaKatuz 分享桌面主题实践，感谢 mytjxs 的动画项目，感谢 ZipZipPipe 的角色设计、GenderSwapAI 的资料整理、StephenQiu 的伴宠图集，以及 CrossPet / lokicorvus 的演示素材。

具体素材的文件对应关系、已知许可及未确认项以 [THIRD-PARTY.md](../THIRD-PARTY.md) 为准。
