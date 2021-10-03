# 닥사 현황 애드온
닥사할때 득템 현황을 상시 표기해주는 애드온입니다

맵 넘어가던가 캐선하던가 할때 목록은 초기화되요

`/ft`, `/farmtracker`, `/파밍` 명령어로 활성화/비활성화를 할수있습니다

맵마다 수동으로 활성화를 해야하고, 한번 활성화 한 맵은 다음 입장시 자동으로 활성화 된 상태로 남겨집니다

하지만 활성화가 한번도 안된 맵으로 이동시 애드온은 숨겨집니다. 활성화 된 맵에서 위 명령어를 한번 더 입력시 다음 활성화까지 그 맵은 비활성화 처리가 됩니다

### 설치방법:
1. ipf 파일 다운 후 `Nexon/TreeOfSavior/data` 폴더에 넣기
2. `Nexon/TreeOfSavior/addons` 폴더에 `farmtracker` 폴더 생성

# FarmTracker
This addon displays a window that keeps track of item acquisitions.
The list is not persistent - it resets every time you move to a new map.

By default, the addon is disabled. You need to enable per map using `/ft` or `/farmtracker` commands.

Once enabled, the addon stays enabled for that map, meaning that the next time you enter it, the addon stays visible.

You can enter the command once more to disable the addon, and the addon will stay disabled for that map until enabled again.

### Installation:
1. Download the ipf file and place it in `Nexon/TreeOfSavior/data`
2. Go to `Nexon/TreeOfSavior/addons` and create a new folder named `farmtracker`