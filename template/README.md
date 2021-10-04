# Addon Template
애드온 제작 표본 파일들입니다.

### 설치방법:
1. ipf 파일 다운 후 `Nexon/TreeOfSavior/data` 폴더에 넣기
2. `Nexon/TreeOfSavior/addons/template` 폴더 생성
3. `Nexon/TreeOfSavior/data/addon_d/template` 폴더 생성
4. `Nexon/TreeOfSavior/data/addon_d/template` 폴더 속에 `template.lua` 다운받아서 넣기
5. `Developer Console` 애드온 설치
6. `dofile("../data/addon_d/template/template.lua");` 명렁어 `Developer Console` 안에서 사용
7. 애드온 제작 과정중 `template.lua` 파일 수정할때마다 `dofile()` 명령어로 실시간 로딩
8. 애드온 제작이 끝났다면 애드온 명칭과 이름 본인이 희망하는 이름으로 변경
9. IpfSuite 을 통해 패키징을 한 이후 애드온 배포

# Addon Template
Based on several addon development experience, this is the baseline code required to start addon development.

I recommend keeping the template.ipf addon always installed, as it will help you always start creating new addon ideas without having to recreate and repackage an ipf every time you want to create an addon.

### Installation and Usage:
1. Download the .ipf file and place it in `Nexon/TreeOfSavior/data`
2. Create the following folder `Nexon/TreeOfSavior/addons/template`
3. Create the following folder `Nexon/TreeOfSavior/data/addon_d/template`
4. Download the `template.lua` source file and place it in the `Nexon/TreeOfSavior/data/addon_d/template` folder
5. Install `Developer Console` addon through the addon manager
6. Use the `dofile("../data/addon_d/template/template.lua");` command inside the `Developer Console`
7. Every time you modify `template.lua` during your addon development, reload the source through the same `dofile()` command above
8. Once complete with your addon development, rename the addon from `template` to the name of your choice. Make sure you make the changes in both the xml and lua.
9. Use IPFSuite to package and distribute the addon.
