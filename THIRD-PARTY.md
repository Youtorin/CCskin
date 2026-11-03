# 素材来源、版权与许可说明

本文件记录 CCskin 1.3.0 实际包含的素材，许可复核日期为 2026-11-03。署名、下载地址与许可状态分别记录；未发现许可证时，不推断为公共领域、MIT 或允许商业使用。

## 授权范围

根目录 [LICENSE](LICENSE) 中的 MIT 许可适用于本项目原创代码和原创文字文档，包括主题引擎、启动/安装/恢复脚本、样式、交互及测试。下列第三方素材、素材描述文件、其美术改编和截图中的第三方画面均不适用该 MIT 授权；本项目不会代替上游作者更改其许可。演示页面的原创 HTML、CSS、JavaScript 代码与其中显示的美术素材分别授权。

已明确授权的素材保留其原许可、作者署名、来源链接和修改说明。未确认许可的条目仅记录来源与当前状态，不构成 CCskin 对其再分发、改编或商业使用的授权。代码与素材分别适用对应许可，不能任选其一覆盖整个仓库。

## 文件清单

| 文件 | 来源与署名 | 处理方式 | 许可状态 |
| --- | --- | --- | --- |
| `assets/home.webp` | GPT 龙娘角色设计 ZipZipPipe；经 [GenderSwapAI 角色页](https://genderswapai.com/zh-CN/ai-gijinka/gpt) 获取 | 保留下载文件；CSS 缩放、混合与蒙版显示 | 未确认适用于该文件的独立再分发许可证，不套用 CrossPet 许可 |
| `assets/chat.png` | 项目委托者提供的横版 GPT 龙娘图片；相关角色设计署名 ZipZipPipe | 原始像素未修改；CSS 透明度与蒙版显示 | 具体横图制作者及独立许可尚待确认；用户提供不等于公开授权 |
| `assets/pet.json`、`assets/spritesheet.webp` | [StephenQiu / stephen-qiu 的 voira-chatgpt](https://codex-pets.net/api/pets/voira-chatgpt/share-data) | 提取原文件，按图集帧播放交互动作 | 原下载包未附独立许可证；本次复核的发布元数据也未提供许可字段，不能视作已获得任意再分发或商用授权 |
| `assets/startup.mp4` | [mytjxs/codex-startup-animation v1.0.0](https://github.com/mytjxs/codex-startup-animation/releases/tag/v1.0.0) | 提取原 MP4 并重命名，未重新编码 | 仓库和包内说明中未确认独立媒体再分发许可证 |
| `demo/assets/startup-poster.png` | 上述启动动画的本地预览海报 | 用作播放器静态预览 | 沿用原视频的权利边界，不另行声明开放许可 |
| `demo/assets/crosspet-proud.webp` | [CrossPet / lokicorvus](https://github.com/lokicorvus/crosspet)；GPT 原角色设计 ZipZipPipe | 图片未修改；添加 CSS 缩放、位移与点击动画 | [CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/deed.zh-hans)；适用于此素材及对应改编 |
| `docs/images/demo-v05.png` | 本项目演示界面截图，包含上述角色及 CrossPet 素材 | 记录设计，不含真实账号、项目或聊天列表 | 不主张第三方画面的独占权；CrossPet 部分与对应改编遵循 CC BY-NC-SA 4.0，其他元素按各自来源处理 |

## 来源与版本

### 角色立绘

[GenderSwapAI 角色页](https://genderswapai.com/zh-CN/ai-gijinka/gpt) 将该版形象创作者标为 **ZipZipPipe**，并区分原立绘、网站制作的二创参考和社区素材。该页指向的 [ZipZipPipe 原始发布帖](https://www.bilibili.com/opus/1233069202138464289) 可确认作品来源，但本次读取的正文未提供明确的再分发许可证。页面中某一作品的许可不能推广到全部图片。本仓库不包含角色三视图，也不镜像整站图库。

### 原生主题伴宠

- 名称：`ChatGPT · 银白龙裔`；标识 `voira-chatgpt`；图集规范版本 `2`。
- 发布者：StephenQiu，账号 `stephen-qiu`；版本时间戳 `1793361924612`。
- [发布信息](https://codex-pets.net/api/pets/voira-chatgpt/share-data) · [原始下载接口](https://codex-pets.net/api/pets/voira-chatgpt/download?v=1793361924612)。
- 图集尺寸 1536 × 2288，单帧 192 × 208。

此图集与演示中的 CrossPet 图片不是同一素材，许可不能相互替代。本项目未复制 `codex-pets` CLI 源码，也不将其软件许可当作美术素材许可。

### 启动视频

视频来自 [mytjxs/codex-startup-animation](https://github.com/mytjxs/codex-startup-animation)，不是 CCskin 原创视频。仅使用媒体，未运行或复制上游 EXE、C# 启动器和安装脚本。

- [v1.0.0 原始 ZIP](https://github.com/mytjxs/codex-startup-animation/releases/download/v1.0.0/codex-startup-animation-v1.0.0-win-x64.zip)。
- 原 ZIP SHA-256：`682928d2e6ce85bfb3d83acadb4e85da9efe4948a593a63e4dc2e605a08ff524`。
- 本仓库所有文件的校验值见根目录 `SHA256SUMS.txt`。

### CrossPet 演示素材

许可依据：[CrossPet 角色素材声明（固定版本）](https://github.com/lokicorvus/crosspet/blob/6e98970f6ff9b44e8ac85215241cabcd78f67d92/characters/LICENSE.md)，协议：[CC BY-NC-SA 4.0](https://creativecommons.org/licenses/by-nc-sa/4.0/legalcode)。本仓库随附未经改写的 [上游声明副本](licenses/CrossPet-art-NOTICE.md) 和 [许可全文](licenses/CC-BY-NC-SA-4.0.txt)。声明副本中的目录名、项目名称与 Issue 入口均指 CrossPet 上游，不扩大其在 CCskin 中的适用文件范围。

保留署名 **CrossPet（lokicorvus）与 GPT 原角色设计作者 ZipZipPipe**。图片像素未修改，演示增加了 CSS 缩放、位移与点击动画；基于该素材形成的美术改编沿用 CC BY-NC-SA 4.0，遵守非商业、署名与相同方式共享要求。原创播放与交互代码按 MIT 授权，其他来源的视频、图片不因此自动适用 CrossPet 的许可。

该许可的非商业性限制不符合 [OSI 开源定义](https://opensource.org/osd) 对用途不得歧视的要求，因此不能将其称为允许任意用途的开源软件许可证。分发本素材及改编时须保留适用的署名、来源、许可、免责说明与修改记录；不能以根目录 MIT 许可取代这些条件。

## 代码、商标与更正

主题引擎、启动/恢复脚本、样式及交互为本项目独立实现，原创代码和原创文字文档由本项目按 [MIT](LICENSE) 授权。Dream Skin 是设计与接入思路参考，未作为运行依赖；两个参考仓库的 MIT 声明及固定版本见 [上游说明](docs/UPSTREAM.md)。本项目选择同一代码许可，不会因此取得第三方素材的 MIT 授权。

素材与角色相关权利仍归各自权利人。收录、署名或提供链接不能替代实际许可；未确认项仍需向权利方核实，取得适用授权或完成替换、移除后，才能据此声明相应的分发权利。本次代码开源不代表全部素材的授权已补齐。OpenAI、ChatGPT、Codex 等名称和标识归各自权利人，本项目无官方合作或认可含义。

如有来源补充、署名错误或权利异议，可在 [Issues](https://github.com/Youtorin/CCskin/issues) 提供文件路径和原始发布链接，供维护者核实并更正、替换或移除。
